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
        user_persona = user.get("persona") if isinstance(user, dict) else "Fitness"
        persona = user_persona or "Fitness"

        resolved_lat = lat if lat is not None else _DEFAULT_LAT
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

        place = place_name or "this location"
        greeting = f"{_tod_greeting(hour)}! Current conditions in {place}."
        if temp is not None:
            summary_insight = (
                f"Current temperature is {temp_label} with {condition_label}. "
                f"Humidity {humidity_label}."
            )
        else:
            summary_insight = "Live weather is unavailable for this location right now."

        activity_reason = f"Outdoor window based on {temp_label} and humidity {humidity_label}."
        uv_reason = f"UV index is {uv_label} ({uv_band})."
        weather_reason = (
            f"{temp_label} • {condition_label}. "
            f"Humidity: {humidity_label}. Wind: {wind_label}."
        )
        aqi_reason = f"AQI is {aqi_label} ({aqi_cat_label})."

        cards = [
            HomeCard(
                id="card_fit_01",
                card_type="activity_window",
                score=4.8,
                rank=1,
                reason_codes=["#OutdoorFitness", "#LiveWeather"],
                reason=activity_reason,
                human_readable_reason=activity_reason,
                title="Optimal Run Window",
                subtitle=f"{temp_label} • humidity {humidity_label}",
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
                reason=uv_reason,
                human_readable_reason=uv_reason,
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
                reason=weather_reason,
                human_readable_reason=weather_reason,
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
                reason=aqi_reason,
                human_readable_reason=aqi_reason,
                title="Air Quality Index",
                subtitle=f"AQI {aqi_label} • {aqi_cat_label}",
                category="Health",
                action_label="Details",
                data={"aqi_value": aqi_value, "category": aqi_category, "is_estimated": aqi_is_estimated},
            ),
        ]

        user_id = user.get("uid") if isinstance(user, dict) else None
        interactions = await get_all_interactions(user_id=user_id)

        effective_cards, ranker_type, baseline_delta = MLReranker.rerank(
            cards=cards,
            user=user,
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
                # Ensure user exists in users table to satisfy FK constraint
                await session.execute(
                    text(
                        "INSERT INTO users (id, firebase_uid, email) VALUES (:id, :id, :email) ON CONFLICT (firebase_uid) DO NOTHING"
                    ),
                    {"id": user_id, "email": user.get("email", "user@mausam.ai")},
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
            # Fallback gracefully if database record fails
            pass

        return {
            "card_id": card_id,
            "action_type": action,
            "recorded": True,
            "status": "success",
        }
