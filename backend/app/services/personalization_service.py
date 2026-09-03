from datetime import datetime
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import text

from app.database.connection import AsyncSessionLocal
from app.ml.dataset import get_all_interactions
from app.ml.reranker import MLReranker
from app.models.user_interaction import UserInteractionModel
from app.schemas.personalization import (
    HomeCard,
    InteractionEvent,
    PersonalizedHomeResponse,
)
from app.services.aqi_service import AQIService
from app.services.weather_service import WeatherService

_DEFAULT_LAT = 12.9716
_DEFAULT_LON = 77.5946
_DEFAULT_TZ = "Asia/Kolkata"


def _tod_greeting(hour: int) -> str:
    if hour < 12:
        return "Good morning"
    if hour < 17:
        return "Good afternoon"
    return "Good evening"


def _uv_band(uv: float) -> str:
    if uv >= 11:
        return "Extreme"
    if uv >= 8:
        return "Very High"
    if uv >= 6:
        return "High"
    if uv >= 3:
        return "Moderate"
    return "Low"


class PersonalizationService:
    @staticmethod
    async def get_home_feed(
        user: dict[str, Any],
        lat: float | None = None,
        lon: float | None = None,
        saved_location_id: str | None = None,
        hour: int | None = None,
        tz: str | None = None,
    ) -> PersonalizedHomeResponse:
        user_id = user.get("uid") if isinstance(user, dict) else None
        
        # 1. Determine User Persona from DB if not passed in dict claims
        persona = "Fitness"
        if isinstance(user, dict) and user.get("persona"):
            persona = user["persona"]
        elif user_id:
            try:
                async with AsyncSessionLocal() as session:
                    res = await session.execute(
                        text("SELECT persona_type FROM users WHERE id = :uid LIMIT 1"),
                        {"uid": user_id},
                    )
                    row = res.fetchone()
                    if row:
                        r = row._mapping
                        persona = r.get("persona_type") or "Fitness"
            except Exception:
                persona = "Fitness"

        # 2. Validate coordinates (prevent 0,0 Null Island)
        if lat is None or (abs(lat) < 0.001 and (lon is None or abs(lon) < 0.001)):
            resolved_lat = _DEFAULT_LAT
            resolved_lon = _DEFAULT_LON
        else:
            resolved_lat = lat
            resolved_lon = lon if lon is not None else _DEFAULT_LON

        if hour is None:
            try:
                hour = datetime.now(ZoneInfo(tz or _DEFAULT_TZ)).hour
            except Exception:
                hour = datetime.now().hour

        temp: float | None = None
        humidity: int | None = None
        condition: str | None = None
        wind: float | None = None
        uv: float | None = None
        place_name: str | None = None
        aqi_value: int | None = None
        aqi_category: str | None = None
        aqi_is_estimated = False
        degraded = False

        try:
            current = await WeatherService.get_current_weather(resolved_lat, resolved_lon)
            temp = current.temperature_celsius
            humidity = current.humidity_percent
            condition = current.condition
            wind = current.wind_speed_kmh
            uv = current.uv_index
            place_name = current.location
            if current.stale:
                degraded = True
        except Exception:
            degraded = True

        try:
            aqi = await AQIService.get_current_aqi(resolved_lat, resolved_lon)
            aqi_value = aqi.aqi_value
            aqi_category = aqi.category
            aqi_is_estimated = aqi.is_estimated
            if aqi.stale:
                degraded = True
        except Exception:
            aqi_is_estimated = True
            degraded = True

        temp_label = f"{temp:.1f}°C" if temp is not None else "unavailable"
        humidity_label = f"{humidity}%" if humidity is not None else "unavailable"
        condition_label = condition or "current conditions"
        wind_label = f"{wind:.1f} km/h" if wind is not None else "unavailable"
        uv_label = f"{uv:.1f}" if uv is not None else "unavailable"
        uv_band = _uv_band(uv) if uv is not None else "unknown"
        aqi_label = str(aqi_value) if aqi_value is not None else "unavailable"
        aqi_cat_label = aqi_category or "unknown"

        place = place_name or "your area"
        greeting = f"{_tod_greeting(hour)}! {persona} recommendations for {place}."

        if temp is not None:
            summary_insight = (
                f"{persona} Focus: {temp_label} with {condition_label}. "
                f"Humidity {humidity_label}, AQI {aqi_label} ({aqi_cat_label})."
            )
        else:
            summary_insight = "Live weather is updating for this location right now."

        # 3. Generate Persona-Specific Cards & Suitability Computations
        cards: list[HomeCard] = []

        if persona == "Health":
            # HEALTH PERSONA: Prioritizes AQI Precautions, Heat/Humidity Index, Weather Comfort, UV Protection
            aqi_num = aqi_value or 50
            if aqi_num > 150:
                health_aqi_title = "High AQI Warning & Mask Advisory"
                health_aqi_sub = f"AQI {aqi_label} ({aqi_cat_label}) • Sensitive groups stay indoors"
            elif aqi_num > 100:
                health_aqi_title = "Moderate Air Quality Precaution"
                health_aqi_sub = f"AQI {aqi_label} ({aqi_cat_label}) • Limit prolonged outdoor exertion"
            else:
                health_aqi_title = "Clean Air Quality Status"
                health_aqi_sub = f"AQI {aqi_label} ({aqi_cat_label}) • Great condition for outdoor breathing"

            # Heat & Humidity Index calculation
            heat_index_str = "Moderate"
            if temp is not None and temp > 33:
                heat_index_str = "High Heat Caution — Stay Hydrated"
            elif humidity is not None and humidity > 80:
                heat_index_str = "High Humidity — Muggy Conditions"

            cards = [
                HomeCard(
                    id="card_health_aqi_01",
                    card_type="aqi",
                    score=4.9,
                    rank=1,
                    reason_codes=["#AirQuality", "#HealthPrecautions"],
                    reason=f"Air quality is {aqi_label} ({aqi_cat_label}). Respiratory health impact is key.",
                    human_readable_reason=f"Air quality is {aqi_label} ({aqi_cat_label}). Respiratory health impact is key.",
                    title=health_aqi_title,
                    subtitle=health_aqi_sub,
                    category="Health",
                    action_label="Air Quality Details",
                    data={"aqi_value": aqi_value, "category": aqi_category, "is_estimated": aqi_is_estimated},
                ),
                HomeCard(
                    id="card_health_caution_02",
                    card_type="health_caution",
                    score=4.5,
                    rank=2,
                    reason_codes=["#HeatIndex", "#Hydration"],
                    reason=f"Temperature {temp_label} with {humidity_label} humidity.",
                    human_readable_reason=f"Temperature {temp_label} with {humidity_label} humidity.",
                    title="Heat & Humidity Comfort",
                    subtitle=f"{heat_index_str} • Drink extra water",
                    category="Health",
                    action_label="Health Advice",
                    data={"temperature_celsius": temp, "humidity_percent": humidity},
                ),
                HomeCard(
                    id="card_wx_03",
                    card_type="weather",
                    score=4.1,
                    rank=3,
                    reason_codes=["#CurrentWeather"],
                    reason=f"{temp_label} • {condition_label}. Humidity: {humidity_label}. Wind: {wind_label}.",
                    human_readable_reason=f"{temp_label} • {condition_label}. Humidity: {humidity_label}. Wind: {wind_label}.",
                    title="Current Weather",
                    subtitle=f"{temp_label} • {condition_label}",
                    category="Weather",
                    action_label="Full Forecast",
                    data={
                        "temperature_celsius": temp,
                        "condition": condition,
                        "humidity_percent": humidity,
                        "wind_speed_kmh": wind,
                    },
                ),
                HomeCard(
                    id="card_uv_04",
                    card_type="uv",
                    score=3.8,
                    rank=4,
                    reason_codes=["#UVIndex", "#SunProtection"],
                    reason=f"UV index is {uv_label} ({uv_band}).",
                    human_readable_reason=f"UV index is {uv_label} ({uv_band}).",
                    title="UV Protection Index",
                    subtitle=f"{uv_band} UV {uv_label} • Apply SPF 30+",
                    category="Health",
                    action_label="Sunscreen Tip",
                    data={"uv_index": uv, "uv_band": uv_band},
                ),
            ]

        elif persona == "Traveler":
            # TRAVELER PERSONA: Prioritizes Travel/Sightseeing Suitability, Rain & Commute Warnings, Packing Tips
            rain_risk = "Low"
            if condition and any(w in condition.lower() for w in ["rain", "drizzle", "shower", "thunderstorm"]):
                rain_risk = "High Rain Risk — Carry Umbrella"
            elif humidity is not None and humidity > 85:
                rain_risk = "Moderate Rain Probability"

            travel_score_label = "Favorable for Travel"
            if temp is not None and temp > 36:
                travel_score_label = "Hot Afternoon — Travel Early or Late"
            elif "rain" in rain_risk.lower():
                travel_score_label = "Expect Rain Delays on Commute"

            packing_item = "Sunglasses & Sunscreen"
            if "rain" in rain_risk.lower():
                packing_item = "Umbrella & Waterproof Footwear"
            elif temp is not None and temp < 18:
                packing_item = "Light Jacket or Sweater"

            cards = [
                HomeCard(
                    id="card_travel_01",
                    card_type="travel_suitability",
                    score=4.9,
                    rank=1,
                    reason_codes=["#TravelSuitability", "#Sightseeing"],
                    reason=f"Travel conditions in {place}: {travel_score_label}.",
                    human_readable_reason=f"Travel conditions in {place}: {travel_score_label}.",
                    title="Sightseeing & Travel Status",
                    subtitle=f"{travel_score_label} • {temp_label}",
                    category="Traveler",
                    action_label="Commute Advice",
                    data={"temperature_celsius": temp, "condition": condition},
                ),
                HomeCard(
                    id="card_commute_02",
                    card_type="weather",
                    score=4.4,
                    rank=2,
                    reason_codes=["#CommuteWarning", "#RainCheck"],
                    reason=f"Current condition: {condition_label}. Rain Status: {rain_risk}.",
                    human_readable_reason=f"Current condition: {condition_label}. Rain Status: {rain_risk}.",
                    title="Commute & Rain Warning",
                    subtitle=f"{rain_risk} • Wind {wind_label}",
                    category="Traveler",
                    action_label="Hourly Forecast",
                    data={
                        "temperature_celsius": temp,
                        "condition": condition,
                        "wind_speed_kmh": wind,
                    },
                ),
                HomeCard(
                    id="card_packing_03",
                    card_type="packing_tips",
                    score=4.0,
                    rank=3,
                    reason_codes=["#PackingTips"],
                    reason=f"Based on {temp_label} and {condition_label}.",
                    human_readable_reason=f"Based on {temp_label} and {condition_label}.",
                    title="Daily Packing Essentials",
                    subtitle=f"Recommended: {packing_item}",
                    category="Traveler",
                    action_label="Packing List",
                    data={"packing_item": packing_item},
                ),
                HomeCard(
                    id="card_aqi_04",
                    card_type="aqi",
                    score=3.5,
                    rank=4,
                    reason_codes=["#AirQuality"],
                    reason=f"AQI is {aqi_label} ({aqi_cat_label}).",
                    human_readable_reason=f"AQI is {aqi_label} ({aqi_cat_label}).",
                    title="Air Quality Index",
                    subtitle=f"AQI {aqi_label} • {aqi_cat_label}",
                    category="Health",
                    action_label="AQI Details",
                    data={"aqi_value": aqi_value, "category": aqi_category, "is_estimated": aqi_is_estimated},
                ),
            ]

        else:
            # FITNESS PERSONA (Default): Outdoor Running Window, Heat/Precip Alert, Weather, AQI
            running_window = "Morning 6:00 AM - 8:30 AM"
            run_suitability = "Great for Running"
            if temp is not None and temp > 32:
                run_suitability = "Hot Exertion Warning"
                running_window = "Evening 6:30 PM - 8:00 PM"
            elif condition and "rain" in condition.lower():
                run_suitability = "Indoor Workout Recommended (Rain)"

            cards = [
                HomeCard(
                    id="card_fit_01",
                    card_type="activity_window",
                    score=4.8,
                    rank=1,
                    reason_codes=["#OutdoorFitness", "#RunningWindow"],
                    reason=f"Outdoor run window based on {temp_label} and humidity {humidity_label}.",
                    human_readable_reason=f"Outdoor run window based on {temp_label} and humidity {humidity_label}.",
                    title="Optimal Outdoor Run Window",
                    subtitle=f"{run_suitability} • {running_window}",
                    category="Fitness",
                    action_label="View Details",
                    data={
                        "temperature_celsius": temp,
                        "humidity_percent": humidity,
                        "condition": condition,
                    },
                ),
                HomeCard(
                    id="card_uv_02",
                    card_type="uv",
                    score=4.2,
                    rank=2,
                    reason_codes=["#UVIndex", "#SunProtection"],
                    reason=f"UV index is {uv_label} ({uv_band}).",
                    human_readable_reason=f"UV index is {uv_label} ({uv_band}).",
                    title="UV Index Alert",
                    subtitle=f"{uv_band} UV {uv_label}",
                    category="Health",
                    action_label="Sunscreen Tip",
                    data={"uv_index": uv, "uv_band": uv_band},
                ),
                HomeCard(
                    id="card_wx_03",
                    card_type="weather",
                    score=3.9,
                    rank=3,
                    reason_codes=["#CurrentWeather"],
                    reason=f"{temp_label} • {condition_label}. Humidity: {humidity_label}. Wind: {wind_label}.",
                    human_readable_reason=f"{temp_label} • {condition_label}. Humidity: {humidity_label}. Wind: {wind_label}.",
                    title="Current Weather",
                    subtitle=f"{temp_label} • {condition_label}",
                    category="Weather",
                    action_label="Full Forecast",
                    data={
                        "temperature_celsius": temp,
                        "condition": condition,
                        "humidity_percent": humidity,
                        "wind_speed_kmh": wind,
                    },
                ),
                HomeCard(
                    id="card_aqi_04",
                    card_type="aqi",
                    score=3.5,
                    rank=4,
                    reason_codes=["#AirQuality"],
                    reason=f"AQI is {aqi_label} ({aqi_cat_label}).",
                    human_readable_reason=f"AQI is {aqi_label} ({aqi_cat_label}).",
                    title="Air Quality Index",
                    subtitle=f"AQI {aqi_label} • {aqi_cat_label}",
                    category="Health",
                    action_label="Details",
                    data={"aqi_value": aqi_value, "category": aqi_category, "is_estimated": aqi_is_estimated},
                ),
            ]

        # 4. Apply ML Reranker (Gated ML / Rules Fallback)
        user_id_for_ml = user.get("uid") if isinstance(user, dict) else None
        interactions = await get_all_interactions(user_id=user_id_for_ml)

        user_context = dict(user) if isinstance(user, dict) else {}
        user_context["persona"] = persona

        effective_cards, ranker_type, baseline_delta = MLReranker.rerank(
            cards=cards,
            user=user_context,
            user_interactions=interactions,
            hour=hour or 12,
        )

        return PersonalizedHomeResponse(
            persona=persona,
            greeting=greeting,
            summary_insight=summary_insight,
            ranker=ranker_type,
            baseline_delta=baseline_delta,
            cards=effective_cards,
            degraded_context=degraded,
            status="degraded" if degraded else "success",
        )

    @staticmethod
    async def record_interaction(user: dict[str, Any], payload: InteractionEvent) -> dict[str, Any]:
        user_id = user.get("uid") or "demo_user"
        card_id = payload.card_id or payload.card_type or "weather"
        action = payload.action_type or payload.action or "view"

        try:
            async with AsyncSessionLocal() as session:
                await session.execute(
                    text(
                        "INSERT INTO users (id, email, persona_type) "
                        "VALUES (:id, :email, 'Fitness') ON CONFLICT (id) DO NOTHING"
                    ),
                    {"id": user_id, "email": user.get("email") or f"{user_id}@mausam.ai"},
                )
                await session.commit()

                item = UserInteractionModel(
                    user_id=user_id,
                    card_id=card_id,
                    action_type=action,
                )
                session.add(item)
                await session.commit()
        except Exception:
            pass

        return {
            "card_id": card_id,
            "action_type": action,
            "recorded": True,
            "status": "success",
        }
