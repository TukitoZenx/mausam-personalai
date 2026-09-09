"""
Chat Service — Mausam AI Orchestrator.

Architecture:
  User Query
      ↓
  Chat Intent & Location Intelligence
      ├── Detect comparison between locations (e.g. "Hyderabad vs Guntur")
      ├── Detect query for specific location (e.g. "weather in Vijayawada")
      ├── Evaluate saved locations comparison (e.g. "lowest temperature in saved locations")
      └── Default to active location / GPS
      ↓
  Weather Tools Execution (Grounded Data Retrieval)
      ├── get_current_weather
      ├── get_hourly_forecast / get_daily_forecast
      ├── get_weather_alerts
      ├── get_air_quality
      └── compare_weather
      ↓
  Gemini Intelligence (Zero-Hallucination Grounding, Multi-Turn Memory, Multilingual)
      ↓ (Graceful Fallback if unconfigured/offline)
  Template & Rule-Based Reasoner (Factual Breakdown + Smart UI Card)
      ↓
  Structured ChatMessageResponse (Reply, Card Data, Actions, Facts, Recommendations)
"""

from datetime import datetime, timezone
import logging
import re
from typing import Any

from app.schemas.chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ReminderCreate,
)
from app.services.gemini_service import GeminiService
from app.services.reminder_service import ReminderService, normalize_time_str
from app.services import weather_tools

logger = logging.getLogger(__name__)

_GREETING_RE = re.compile(
    r"^(hi+|hii+|hello|hey+|yo|hola|namaste|sup|howdy|"
    r"hi there|hey there|hello there|"
    r"good (morning|afternoon|evening|night)|"
    r"నమస్కారం|బాగున్నారా|नमस्ते|வணக்கம்|ನಮಸ್ಕಾರ)"
    r"(\s+(mausam|ai|mausam\s+ai|assistant|there))?"
    r"[\s!.?]*$",
    re.IGNORECASE,
)
_SMALLTALK_RE = re.compile(
    r"^(how are you( doing)?( today)?|how's it going|hows it going|"
    r"what's up|whats up|how do you do|you good|you there|"
    r"ఎలా ఉన్నారు|आप कैसे हैं)"
    r"[\s!.?]*$",
    re.IGNORECASE,
)
_THANKS_RE = re.compile(
    r"^(thanks(\s+a\s+lot)?|thank you(\s+so\s+much|\s+very\s+much)?|thx|ty|tysm|ధన్యవాదాలు|धन्यवाद)[\s!.?]*$",
    re.IGNORECASE,
)
_HELP_RE = re.compile(
    r"^(help|what can you do|who are you|what are you|"
    r"what do you do|how does this work)[\s!.?]*$",
    re.IGNORECASE,
)

_WEATHER_HINTS = (
    "weather", "temperature", "temp", "forecast", "rain", "umbrella", "shower",
    "storm", "thunder", "aqi", "air quality", "pollution", "smog", "humidity",
    "wind", "uv", "wear", "outfit", "clothes", "jacket", "coat", "workout",
    "run", "jog", "fitness", "exercise", "commute", "drive", "hot", "cold",
    "sunny", "cloud", "humid", "visibility", "sunrise", "sunset", "outside",
    "outdoor", "heat", "cool", "chilly", "snow", "drizzle", "cricket", "play",
    "tomorrow", "weekend", "briefing", "radar", "travel", "safe", "safest",
    "varsham", "varsham padutunda", "mausam", "kaisa", "hawa",
)


def _extract_comparison_locations(text: str) -> tuple[str, str] | None:
    """
    Detect location comparison patterns like:
      - 'How is Hyderabad compared to Guntur?'
      - 'Compare Hyderabad and Guntur'
      - 'Hyderabad vs Guntur'
      - 'Compare weather in Delhi and Mumbai'
    """
    clean = text.strip()
    m = re.search(r"compare\s+(?:weather\s+in\s+)?([A-Za-z\s]+?)\s+(?:and|with|to)\s+([A-Za-z\s]+?)(?:\?|$)", clean, re.IGNORECASE)
    if m:
        return m.group(1).strip(), m.group(2).strip()

    m = re.search(r"([A-Za-z\s]+?)\s+(?:compared\s+to|vs\.?|versus)\s+([A-Za-z\s]+?)(?:\?|$)", clean, re.IGNORECASE)
    if m:
        loc1 = re.sub(r"^(how is|how's|what is|what's)\s+", "", m.group(1), flags=re.IGNORECASE).strip()
        loc2 = m.group(2).strip()
        if loc1 and loc2:
            return loc1, loc2

    return None


def _extract_location_mention(text: str) -> str | None:
    """
    Extract explicit location targets mentioned with 'in <City>' or 'for <City>'
    e.g. 'weather in Vijayawada tomorrow' -> 'Vijayawada'
    """
    clean = text.strip()
    # Strip trailing temporal words so they are not captured as part of city name
    truncated = re.sub(r"\b(tomorrow|today|tonight|now|yesterday|this weekend|this evening|next week|the morning)\b.*$", "", clean, flags=re.IGNORECASE).strip()
    m = re.search(r"\b(?:in|at|for)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)\b", truncated, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        stopwords = {
            "the morning", "the evening", "the afternoon", "the night", "my area",
            "this city", "degrees", "celsius", "fahrenheit", "detail", "hours",
            "advance", "a run", "cricket", "outdoor", "walking", "travel",
        }
        if candidate.lower() not in stopwords and len(candidate) > 2:
            return candidate
    return None


def _extract_time_and_frequency(text: str) -> tuple[str | None, str]:
    freq = "once" if "once" in text.lower() else "daily"
    m = re.search(r"\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b", text, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        if any(c.isdigit() for c in candidate):
            if candidate.isdigit():
                val = int(candidate)
                if val <= 12 and f"at {val}" in text.lower():
                    candidate = f"{val}:00"
                elif val <= 24:
                    candidate = f"{val}:00"
            return normalize_time_str(candidate), freq
    return None, freq


def classify_chat_intent(text: str) -> str:
    """Classify user intent: greeting | smalltalk | thanks | help | reminder | compare | saved_locations | weather | general."""
    stripped = text.strip()
    lower = stripped.lower()

    if _GREETING_RE.match(stripped):
        return "greeting"
    if _SMALLTALK_RE.match(stripped):
        return "smalltalk"
    if _THANKS_RE.match(stripped):
        return "thanks"
    if _HELP_RE.match(stripped):
        return "help"
    if any(k in lower for k in ("remind", "reminder", "alarm", "schedule notification", "notify me")):
        return "reminder"
    if _extract_comparison_locations(stripped) is not None:
        return "compare"
    if "saved location" in lower or "saved locations" in lower:
        return "saved_locations"
    if any(k in lower for k in _WEATHER_HINTS) or _extract_location_mention(stripped):
        return "weather"
    return "general"


def _build_structured_card(
    snap: dict[str, Any],
    forecast_list: list[dict[str, Any]] | None,
    alerts: list[dict[str, Any]] | None,
    query_text: str,
) -> dict[str, Any]:
    """
    Construct a structured WeatherAiCardData dictionary for rich Flutter UI rendering.
    """
    lower = query_text.lower()
    temp = snap["temperature_celsius"]
    feels = snap["feels_like_celsius"]
    loc = snap["location"]
    cond = snap["condition"]
    rain_mm = snap.get("rain_mm_1h", 0.0)
    aqi_val = snap.get("aqi", 0)
    aqi_cat = snap.get("aqi_category", "Moderate")

    # 1. Severe Alert Card
    if alerts and len(alerts) > 0:
        top_alert = alerts[0]
        return {
            "cardType": "forecastSummary",
            "category": "OFFICIAL WEATHER WARNING",
            "headline": top_alert.get("headline", "Weather Advisory"),
            "subtitle": f"{loc} · {top_alert.get('severity', 'Warning').upper()}",
            "metrics": [
                {"label": "Status", "value": "Active"},
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
                {"label": "Rain Rate", "value": f"{rain_mm:.1f} mm/h"},
            ],
            "explanation": top_alert.get("description", "Take appropriate precautions."),
            "actionLabel": "View Full Alerts",
            "actionRoute": "/alerts",
        }

    # 2. Workout / Cricket / Running Intent
    if any(w in lower for w in ("workout", "run", "jog", "fitness", "cricket", "play", "sports", "exercise")):
        is_safe = rain_mm == 0 and temp < 34 and aqi_val < 150
        headline = "Favorable Outdoor Window" if is_safe else "Suboptimal Conditions for Outdoor Activity"
        subtitle = "Optimal early morning or late afternoon" if is_safe else "High heat or precipitation risk"
        return {
            "cardType": "activityWindow",
            "category": "ACTIVITY & OUTDOOR INTELLIGENCE",
            "headline": headline,
            "subtitle": subtitle,
            "metrics": [
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Feels Like", "value": f"{feels}°C"},
                {"label": "Rain Risk", "value": "High" if rain_mm > 0 else "Low"},
                {"label": "Air Quality", "value": f"AQI {aqi_val}"},
            ],
            "explanation": f"In {loc}, current temperature is {temp}°C with {cond.lower()}. " + (
                "Ensure hydration and avoid midday peak UV." if is_safe else "Consider moving activity indoors."
            ),
            "actionLabel": "Schedule Reminder",
            "actionRoute": "/chat",
        }

    # 3. Wardrobe / Outfit / Umbrella Intent
    if any(w in lower for w in ("wear", "outfit", "clothes", "jacket", "coat", "umbrella")):
        need_umbrella = rain_mm > 0 or "rain" in cond.lower()
        return {
            "cardType": "clothingWardrobe",
            "category": "WARDROBE ADVISORY",
            "headline": "Carry an Umbrella & Rainwear" if need_umbrella else f"Breathable Attire for {temp}°C",
            "subtitle": f"{loc} · Humidity {snap['humidity_percent']}%",
            "metrics": [
                {"label": "Temp", "value": f"{temp}°C"},
                {"label": "Rain", "value": f"{rain_mm:.1f} mm/h"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
                {"label": "UV Index", "value": f"{snap['uv_index']}"},
            ],
            "explanation": "Rain is active — protect gear with waterproof cover." if need_umbrella else "Light fabrics recommended. Add sunglasses or hat for sun protection.",
            "actionLabel": "Detailed Forecast",
            "actionRoute": "/forecast",
        }

    # 4. Air Quality & Health Intent
    if any(w in lower for w in ("aqi", "air quality", "pollution", "smog", "breathe", "asthma")):
        return {
            "cardType": "healthEnvironment",
            "category": "AIR QUALITY & ENVIRONMENT",
            "headline": f"AQI {aqi_val} · {aqi_cat}",
            "subtitle": f"Monitored in {loc}",
            "metrics": [
                {"label": "AQI", "value": f"{aqi_val}"},
                {"label": "Category", "value": aqi_cat},
                {"label": "Humidity", "value": f"{snap['humidity_percent']}%"},
                {"label": "Wind", "value": f"{snap['wind_speed_kmh']} km/h"},
            ],
            "explanation": "Air quality is elevated — sensitive individuals should minimize prolonged outdoor exertion." if aqi_val > 100 else "Air quality is satisfactory for general outdoor recreation.",
            "actionLabel": "Health Metrics",
            "actionRoute": "/health-metrics",
        }

    # 5. Travel & Forecast Summary (Default Weather Card)
    return {
        "cardType": "forecastSummary",
        "category": "CURRENT CONDITIONS & FORECAST",
        "headline": f"{temp}°C · {cond} in {loc}",
        "subtitle": f"Feels like {feels}°C · Wind {snap['wind_speed_kmh']} km/h",
        "metrics": [
            {"label": "Temp", "value": f"{temp}°C"},
            {"label": "Humidity", "value": f"{snap['humidity_percent']}%"},
            {"label": "AQI", "value": f"{aqi_val} ({aqi_cat})"},
            {"label": "UV", "value": f"{snap['uv_index']}"},
        ],
        "explanation": f"High of {temp}°C expected today with {cond.lower()}.",
        "actionLabel": "View 5-Day Forecast",
        "actionRoute": "/forecast",
    }


def _build_comparison_card(comp: dict[str, Any]) -> dict[str, Any]:
    w1 = comp["location1"]
    w2 = comp["location2"]
    diff = comp["temperature_difference_celsius"]
    headline = f"{comp['warmer_location']} is warmer by {abs(diff):.1f}°C" if diff != 0 else "Both locations share the same temperature"

    return {
        "cardType": "travelPacking",
        "category": "LOCATION COMPARISON",
        "headline": headline,
        "subtitle": f"{w1['location']} vs {w2['location']}",
        "metrics": [
            {"label": f"{w1['location']} Temp", "value": f"{w1['temperature_celsius']}°C"},
            {"label": f"{w2['location']} Temp", "value": f"{w2['temperature_celsius']}°C"},
            {"label": f"{w1['location']} AQI", "value": f"{w1['aqi']}"},
            {"label": f"{w2['location']} AQI", "value": f"{w2['aqi']}"},
        ],
        "explanation": f"{comp['cleaner_air_location']} currently enjoys cleaner air.",
        "actionLabel": "Saved Locations",
        "actionRoute": "/saved-locations",
    }


def _detailed_weather_reply(
    text: str,
    snap: dict[str, Any],
    forecast_list: list[dict[str, Any]] | None,
    hourly_list: list[dict[str, Any]] | None,
    persona: str | None = None,
    health: list[str] | None = None,
    weather_triggers: list[str] | None = None,
    what_matters_most: list[str] | None = None,
    activity_level: str | None = None,
    user_name: str | None = None,
    alerts: list[dict[str, Any]] | None = None,
) -> tuple[str, list[str], list[str]]:
    """
    Generate a user-first, conversational advisory reply grounded in live weather data.
    Directly answers the user's dilemma (commute, workout, cricket, wardrobe, health)
    before highlighting key weather numbers.
    """
    loc = snap["location"]
    temp = snap["temperature_celsius"]
    feels = snap["feels_like_celsius"]
    cond = snap["condition"]
    hum = snap["humidity_percent"]
    wind = snap["wind_speed_kmh"]
    uv = snap["uv_index"]
    rain_mm = snap.get("rain_mm_1h", 0.0)
    aqi_val = snap.get("aqi", 0)
    aqi_cat = snap.get("aqi_category", "Moderate")

    facts: list[str] = [
        f"Temperature in {loc} is {temp}°C (feels like {feels}°C) with {cond}.",
        f"Humidity is {hum}%, Wind speed is {wind} km/h, and UV Index is {uv}.",
        f"Air Quality Index is {aqi_val} ({aqi_cat}).",
    ]
    if rain_mm > 0:
        facts.append(f"Precipitation rate is {rain_mm:.1f} mm/h.")

    recommendations: list[str] = []

    # 1. Severe alert priority
    alert_warning_str = ""
    if alerts and len(alerts) > 0:
        top_alert = alerts[0]
        headline = top_alert.get("headline", "Weather Advisory")
        desc = top_alert.get("description", "Take appropriate precautions.")
        alert_warning_str = f"⚠️ **SAFETY ALERT: {headline}**\n{desc}\n\n"
        recommendations.append(f"Safety priority: {desc}")

    # 2. Personalized Greeting / Name Address
    name_str = f"{user_name}, " if user_name else ""
    lower = text.lower()

    # 3. Intent-Specific Direct User Answer & Practical Action
    direct_answer = ""
    action_advice = ""

    if any(w in lower for w in ("cricket", "play", "sports", "match", "game")):
        if rain_mm > 0 or "thunder" in cond.lower() or "rain" in cond.lower():
            direct_answer = (
                f"{name_str}outdoor cricket or sports are **not recommended** right now in {loc}. "
                f"Rain is falling ({rain_mm:.1f} mm/h) and pitches will be damp and slippery, posing an injury risk."
            )
            action_advice = "Postpone your match or switch to an indoor sports venue until the rain clears."
            recommendations.append("Ground is wet from rain; postpone outdoor cricket to prevent slipping.")
        elif temp >= 35 or feels >= 38:
            direct_answer = (
                f"{name_str}playing cricket under the midday sun right now in {loc} isn't advisable due to high heat "
                f"({temp}°C, feels like {feels}°C)."
            )
            action_advice = "Consider shifting your match to early morning or after 5:30 PM when the UV index subsides."
            recommendations.append(f"High temperature ({temp}°C) creates heat stress risk; play during cooler evening hours.")
        else:
            direct_answer = (
                f"{name_str}yes! Conditions in {loc} are **favorable for playing cricket** right now. "
                f"The temperature is {temp}°C with {cond.lower()} skies and a gentle breeze ({wind} km/h)."
            )
            action_advice = "Stay well hydrated between overs and enjoy your match!"
            recommendations.append("Conditions are suitable for outdoor sports. Maintain proper hydration.")

    elif any(w in lower for w in ("run", "running", "jog", "workout", "fitness", "exercise")):
        if rain_mm > 0 or "thunder" in cond.lower():
            direct_answer = (
                f"{name_str}outdoor running or workouts are **not recommended** right now in {loc}. "
                f"Rain is actively falling ({rain_mm:.1f} mm/h) with wet road surfaces."
            )
            action_advice = "An indoor treadmill or bodyweight routine is much safer and more comfortable today."
            recommendations.append("Active rain present; shift cardio workout indoors.")
        elif temp >= 34 or feels >= 37 or aqi_val > 150:
            direct_answer = (
                f"{name_str}hold off on strenuous outdoor running right now in {loc}. "
                f"Heat index is at {feels}°C with AQI {aqi_val} ({aqi_cat})."
            )
            action_advice = "Shift your training session to an indoor air-conditioned gym or early tomorrow morning."
            recommendations.append("Elevated heat and AQI; limit strenuous outdoor cardio.")
        else:
            direct_answer = (
                f"{name_str}it's a **great time for your workout** in {loc}! "
                f"Current temperature is {temp}°C (feels like {feels}°C) with {cond.lower()} skies."
            )
            action_advice = "Pace yourself, hydrate adequately, and make the most of this clear weather window."
            recommendations.append("Favorable outdoor workout conditions. Maintain hydration.")

    elif any(w in lower for w in ("umbrella", "raincoat")):
        if rain_mm > 0 or "rain" in cond.lower() or "drizzle" in cond.lower():
            direct_answer = (
                f"{name_str}**yes, definitely take an umbrella** before stepping out in {loc}! "
                f"Precipitation is active ({rain_mm:.1f} mm/h) with {hum}% humidity."
            )
            action_advice = "Keep your bag or electronics in water-resistant sleeves."
            recommendations.append("Carry an umbrella or raincoat; precipitation is active.")
        else:
            direct_answer = (
                f"{name_str}**no umbrella needed** right now in {loc}! "
                f"Skies are {cond.lower()} with no active rain."
            )
            action_advice = "You can travel comfortably without rain gear today."
            recommendations.append(f"No precipitation in {loc}; rain protection not required.")

    elif any(w in lower for w in ("wear", "outfit", "clothes", "jacket", "coat", "dressing")):
        if rain_mm > 0 or "rain" in cond.lower():
            direct_answer = (
                f"{name_str}wear **water-resistant footwear and carry an umbrella or lightweight raincoat** in {loc} today."
            )
            action_advice = f"With {hum}% humidity, breathable waterproof layers will keep you dry without feeling stuffy."
            recommendations.append("Water-resistant layers and wet-traction shoes recommended.")
        elif temp >= 32:
            direct_answer = (
                f"{name_str}go with **light, loose-fitting cotton clothing** today in {loc}. "
                f"The temperature is {temp}°C (feels like {feels}°C) with {cond.lower()} skies."
            )
            action_advice = f"UV index is {uv}, so consider sunglasses or a hat if you'll be in the sun."
            recommendations.append("Light, breathable cotton fabrics and sun protection advised.")
        elif temp < 20:
            direct_answer = (
                f"{name_str}it's cool outside ({temp}°C) in {loc} with a {wind} km/h breeze. "
                f"A **light jacket, cardigan, or sweater** is ideal."
            )
            action_advice = "Layer up comfortably, especially if heading out early or after dark."
            recommendations.append("Light jacket or sweater recommended for cool temperatures.")
        else:
            direct_answer = (
                f"{name_str}**comfortable casual wear** is perfect for {loc} today. "
                f"The temperature is a pleasant {temp}°C with {cond.lower()} conditions."
            )
            action_advice = "Standard everyday clothes will keep you comfortable all day."
            recommendations.append("Standard comfortable everyday attire is appropriate.")

    elif any(w in lower for w in ("aqi", "air quality", "pollution", "smog", "breathe", "asthma")):
        if health and any(h.lower() in ("asthma", "allergy", "allergies", "respiratory") for h in health):
            direct_answer = (
                f"{name_str}for your respiratory sensitivity, please take note: the AQI in {loc} is currently "
                f"**{aqi_val} ({aqi_cat})** with {hum}% humidity."
            )
            action_advice = (
                "Keep your rescue inhaler handy and avoid prolonged outdoor cardio."
                if aqi_val > 100 else
                "Air quality is clean and safe for your normal outdoor activities today."
            )
            recommendations.append(f"AQI is {aqi_val} ({aqi_cat}); sensitive individuals should take precautions.")
        elif aqi_val > 150:
            direct_answer = (
                f"{name_str}air quality in {loc} is currently **{aqi_cat} (AQI {aqi_val})**. "
                f"Pollutant levels are elevated."
            )
            action_advice = "Wear an N95 mask if outdoors for extended periods and limit intense aerobic workouts."
            recommendations.append("Unhealthy air quality; wear an N95 mask outdoors and limit strenuous cardio.")
        else:
            direct_answer = (
                f"{name_str}the air quality in {loc} is **{aqi_cat} (AQI {aqi_val})**, which is favorable for outdoor routines."
            )
            action_advice = "You can freely enjoy outdoor activities and fresh air."
            recommendations.append("Air quality is satisfactory for general outdoor recreation.")

    else:
        direct_answer = (
            f"{name_str}here is your personal weather briefing for {loc}: "
            f"Conditions are **{cond.lower()}** with a temperature of **{temp}°C** (feels like **{feels}°C**)."
        )
        action_advice = f"Wind is blowing at {wind} km/h with {hum}% humidity and AQI **{aqi_val} ({aqi_cat})**."
        recommendations.append(f"Plan your schedule around {cond.lower()} conditions and temperature highs near {temp}°C.")

    # 4. User Triggers & Health Notes
    personalized_notes: list[str] = []
    if weather_triggers:
        if any("humidity" in t.lower() for t in weather_triggers) and hum >= 65:
            personalized_notes.append(f"• **Sensitivity note**: Humidity is high ({hum}%), which might feel muggy or triggering.")
        if any("heat" in t.lower() for t in weather_triggers) and temp >= 32:
            personalized_notes.append(f"• **Heat sensitivity**: High heat ({temp}°C) detected—stay well hydrated.")
        if any("rain" in t.lower() for t in weather_triggers) and rain_mm > 0:
            personalized_notes.append(f"• **Precipitation alert**: Rain is actively falling ({rain_mm:.1f} mm/h).")

    # 5. Hourly window context
    hourly_block = ""
    if hourly_list:
        h_str = " · ".join([f"{h['hour']} {h['temperature_celsius']}°C" for h in hourly_list[:4]])
        hourly_block = f"\n\n**Next Hours**: {h_str}"

    forecast_block = ""
    if forecast_list:
        f_str = " · ".join([f"{d['day'][:3]}: {d['high_celsius']}°/{d['low_celsius']}°" for d in forecast_list[:3]])
        forecast_block = f"\n**Coming Days**: {f_str}"

    trigger_text = ("\n" + "\n".join(personalized_notes)) if personalized_notes else ""
    summary_line = f"\n\n**Conditions in {loc}**: **{temp}°C**, {cond}, AQI **{aqi_val}** ({aqi_cat}), Humidity {hum}%."

    full_text = (
        f"{alert_warning_str}"
        f"{direct_answer}\n\n"
        f"{action_advice}"
        f"{trigger_text}"
        f"{summary_line}"
        f"{hourly_block}"
        f"{forecast_block}"
    )

    return full_text, facts, recommendations


class ChatService:

    @staticmethod
    async def process_message(user: dict[str, Any], payload: ChatMessageRequest) -> ChatMessageResponse:
        text = payload.text.strip()
        intent = classify_chat_intent(text)

        # 1. Reminder Intent
        if intent == "reminder":
            extracted_time, freq = _extract_time_and_frequency(text)
            if extracted_time:
                try:
                    created = await ReminderService.create_reminder(
                        user=user,
                        payload=ReminderCreate(time_of_day=extracted_time, frequency=freq),
                    )
                    reply = (
                        f"I have scheduled your {freq} weather reminder for **{created.time_of_day}**. "
                        f"You will receive a daily routine notification with conditions for your area."
                    )
                    return ChatMessageResponse(
                        reply=reply,
                        intent="reminder",
                        source="template",
                        reminder_created=True,
                        reminder_details=created.model_dump(),
                        suggested_actions=["Today's weather", "AQI right now", "List reminders"],
                    )
                except Exception as exc:
                    logger.warning("Failed to create reminder from chat: %s", exc)
                    return ChatMessageResponse(
                        reply=f"I understood you want a reminder at {extracted_time}, but encountered an error saving it: {exc}",
                        intent="reminder",
                        source="template",
                        suggested_actions=["Try setting a reminder again", "Today's weather"],
                    )
            return ChatMessageResponse(
                reply=(
                    "I'd be glad to set a weather reminder for you! "
                    "What time would you like to receive it (e.g., *7:00 AM* or *9:00 PM*) and how often (*daily* or *once*)?"
                ),
                intent="reminder",
                source="template",
                suggested_actions=["Remind me daily at 7:00 AM", "Remind me at 9:00 PM daily", "Today's weather"],
            )

        # 2. Small Talk / Greetings
        if intent in ("greeting", "smalltalk", "thanks", "help"):
            greetings = {
                "smalltalk": "I'm doing well and ready! Ask me about current weather, rain chances, what to wear, or travel safety.",
                "thanks": "You're welcome! Let me know if you need another weather update or recommendation.",
                "help": "I'm **Mausam AI**. I can check live weather, 5-day forecasts, rain probabilities, AQI, outdoor activity suitability, and set reminders. What would you like to know?",
                "greeting": "Hello! I'm **Mausam AI**. How can I help you with today's weather or your schedule?",
            }
            return ChatMessageResponse(
                reply=greetings.get(intent, "Hello! How can I help with the weather?"),
                intent=intent,
                source="template",
                suggested_actions=["What's the weather right now?", "Will it rain today?", "Is air quality good?"],
            )

        # 3. Location Comparison Intent (e.g. "Hyderabad vs Guntur")
        comp_locs = _extract_comparison_locations(text)
        if comp_locs:
            loc1, loc2 = comp_locs
            try:
                comp_data = await weather_tools.compare_weather(
                    loc1, loc2,
                    default_lat=payload.resolved_lat or 17.3850,
                    default_lon=payload.resolved_lon or 78.4867,
                )
                comp_card = _build_comparison_card(comp_data)

                # Try Gemini with comparison grounding
                gemini_res = await GeminiService.generate_response(
                    user_message=text,
                    comparison_data=comp_data,
                    history=payload.history,
                )
                if gemini_res:
                    reply_text, actions, card = gemini_res
                    return ChatMessageResponse(
                        reply=reply_text,
                        intent="compare",
                        source="gemini",
                        card_data=card or comp_card,
                        suggested_actions=actions,
                    )

                w1 = comp_data["location1"]
                w2 = comp_data["location2"]
                diff = comp_data["temperature_difference_celsius"]
                reply = (
                    f"**Weather Comparison: {w1['location']} vs {w2['location']}**\n\n"
                    f"• **{w1['location']}**: **{w1['temperature_celsius']}°C** (feels like {w1['feels_like_celsius']}°C), {w1['condition']}, AQI **{w1['aqi']}**\n"
                    f"• **{w2['location']}**: **{w2['temperature_celsius']}°C** (feels like {w2['feels_like_celsius']}°C), {w2['condition']}, AQI **{w2['aqi']}**\n\n"
                    f"**Summary**: {comp_data['warmer_location']} is warmer by {abs(diff):.1f}°C. {comp_data['cleaner_air_location']} has cleaner air quality."
                )
                return ChatMessageResponse(
                    reply=reply,
                    intent="compare",
                    source="template",
                    card_data=comp_card,
                    suggested_actions=[f"Forecast for {w1['location']}", f"Forecast for {w2['location']}", "Will it rain today?"],
                )
            except Exception as exc:
                logger.warning("Comparison failed: %s", exc)

        # 4. Saved Locations Query (e.g. "Which saved location has the lowest temperature?")
        if intent == "saved_locations" and payload.saved_locations:
            try:
                results = []
                for loc_item in payload.saved_locations[:5]:
                    name = loc_item.get("name")
                    lat = loc_item.get("latitude")
                    lon = loc_item.get("longitude")
                    if lat and lon:
                        cur = await weather_tools.get_current_weather(
                            location=name, default_lat=lat, default_lon=lon, default_name=name
                        )
                        results.append(cur)

                if results:
                    sorted_by_temp = sorted(results, key=lambda x: x["temperature_celsius"])
                    coldest = sorted_by_temp[0]
                    warmest = sorted_by_temp[-1]
                    breakdown = "\n".join([f"• **{r['location']}**: **{r['temperature_celsius']}°C**, {r['condition']}, AQI {r['aqi']}" for r in results])
                    reply = (
                        f"Here is the weather across your saved locations:\n\n{breakdown}\n\n"
                        f"**Lowest Temperature**: **{coldest['location']}** at **{coldest['temperature_celsius']}°C**.\n"
                        f"**Highest Temperature**: **{warmest['location']}** at **{warmest['temperature_celsius']}°C**."
                    )
                    return ChatMessageResponse(
                        reply=reply,
                        intent="saved_locations",
                        source="template",
                        suggested_actions=[f"Weather in {coldest['location']}", "Air quality index", "Today's weather"],
                    )
            except Exception as exc:
                logger.warning("Saved locations query failed: %s", exc)

        # 5. Location Resolution for Target Query
        target_location = _extract_location_mention(text) or payload.active_location_name
        default_lat = payload.resolved_lat or 17.3850
        default_lon = payload.resolved_lon or 78.4867
        default_name = payload.active_location_name or "Active Location"

        weather_snapshot = None
        forecast_list = None
        hourly_list = None
        alerts_list = None

        try:
            weather_snapshot = await weather_tools.get_current_weather(
                location=target_location,
                default_lat=default_lat,
                default_lon=default_lon,
                default_name=default_name,
            )
            lat = weather_snapshot["latitude"]
            lon = weather_snapshot["longitude"]
            forecast_list = await weather_tools.get_daily_forecast(
                location=target_location, default_lat=lat, default_lon=lon, default_name=weather_snapshot["location"]
            )
            hourly_list = await weather_tools.get_hourly_forecast(
                location=target_location, default_lat=lat, default_lon=lon, default_name=weather_snapshot["location"]
            )
            alerts_list = await weather_tools.get_weather_alerts(
                location=target_location, persona=payload.persona, default_lat=lat, default_lon=lon
            )
        except Exception as exc:
            logger.warning("Weather tool fetch failed: %s", exc)

        if weather_snapshot is None and intent == "weather":
            return ChatMessageResponse(
                reply=(
                    "I could not retrieve live weather data right now. "
                    "Please make sure your location services are enabled or specify a city name (e.g., *'Weather in Guntur'*)."
                ),
                intent="weather",
                source="template",
                suggested_actions=["Weather in Hyderabad", "Weather in Guntur", "Check air quality"],
            )

        # Build fallback structured card
        structured_card = None
        if weather_snapshot:
            structured_card = _build_structured_card(
                snap=weather_snapshot,
                forecast_list=forecast_list,
                alerts=alerts_list,
                query_text=text,
            )

        user_context = None
        if (
            payload.persona
            or payload.health_concerns
            or payload.weather_triggers
            or payload.what_matters_most
            or payload.activity_level
            or payload.user_name
        ):
            user_context = {
                "name": payload.user_name,
                "persona": payload.persona,
                "health_concerns": payload.health_concerns or [],
                "weather_triggers": payload.weather_triggers or [],
                "what_matters_most": payload.what_matters_most or [],
                "activity_level": payload.activity_level,
            }

        # 6. Call Gemini Service with full Grounding
        gemini_result = await GeminiService.generate_response(
            user_message=text,
            weather_data=weather_snapshot,
            forecast_data=forecast_list,
            user_context=user_context,
            hourly_data=hourly_list,
            alerts_data=alerts_list,
            saved_locations=payload.saved_locations,
            history=payload.history,
        )

        if gemini_result is not None:
            reply_text, suggested_actions, gemini_card = gemini_result
            return ChatMessageResponse(
                reply=reply_text,
                intent=intent,
                source="gemini",
                weather_data=weather_snapshot,
                card_data=gemini_card or structured_card,
                suggested_actions=suggested_actions,
                location_context={"location": weather_snapshot.get("location") if weather_snapshot else target_location},
            )

        # 7. Deterministic Fallback Template
        if weather_snapshot is not None:
            reply, facts, recs = _detailed_weather_reply(
                text=text,
                snap=weather_snapshot,
                forecast_list=forecast_list,
                hourly_list=hourly_list,
                persona=payload.persona,
                health=payload.health_concerns,
                weather_triggers=payload.weather_triggers,
                what_matters_most=payload.what_matters_most,
                activity_level=payload.activity_level,
                user_name=payload.user_name,
                alerts=alerts_list,
            )
            return ChatMessageResponse(
                reply=reply,
                intent="weather",
                source="template",
                weather_data=weather_snapshot,
                card_data=structured_card,
                facts=facts,
                recommendations=recs,
                location_context={"location": weather_snapshot.get("location")},
                suggested_actions=["Will it rain tomorrow?", "What should I wear?", "Hourly temperature breakdown"],
            )

        return ChatMessageResponse(
            reply=(
                "I am **Mausam AI**, your personal weather intelligence assistant. "
                "Ask me any question about current weather, forecasts, outdoor workout suitability, wardrobe, or air quality."
            ),
            intent="general",
            source="template",
            suggested_actions=["Today's weather", "Will it rain today?", "Air quality right now"],
        )
