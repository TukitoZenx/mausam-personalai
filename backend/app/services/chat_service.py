from datetime import datetime, timezone
import logging
import re
from typing import Any

from app.schemas.chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ReminderCreate,
)
from app.services.aqi_service import AQIService
from app.services.reminder_service import ReminderService, normalize_time_str
from app.services.weather_service import WeatherService

logger = logging.getLogger(__name__)

_DEFAULT_LAT = 12.9716  # Bengaluru default
_DEFAULT_LON = 77.5946


def _extract_time_and_frequency(text: str) -> tuple[str | None, str]:
    """
    Extract time and frequency from strings like:
    'remind me daily at 7am'
    'set a reminder at 08:30'
    'remind me at 9 pm once'
    """
    freq = "once" if "once" in text.lower() else "daily"

    # Match time: 7am, 7:00 am, 7 pm, 19:30, 07:00, 7:00
    m = re.search(r"\b(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b", text, re.IGNORECASE)
    if m:
        candidate = m.group(1).strip()
        # Verify candidate contains at least one digit
        if any(c.isdigit() for c in candidate):
            # If it's just a number 1-12 without am/pm, check if preceded by 'at'
            if candidate.isdigit():
                val = int(candidate)
                if val <= 12 and f"at {val}" in text.lower():
                    candidate = f"{val}:00"
                elif val <= 24:
                    candidate = f"{val}:00"
            return normalize_time_str(candidate), freq

    return None, freq


class ChatService:

    @staticmethod
    async def process_message(user: dict[str, Any], payload: ChatMessageRequest) -> ChatMessageResponse:
        text = payload.text.strip()
        lower_text = text.lower()

        # 1. Intent Detection: Reminder vs Weather
        is_reminder_intent = any(k in lower_text for k in [
            "remind", "reminder", "alarm", "schedule notification", "notify me"
        ])

        if is_reminder_intent:
            extracted_time, freq = _extract_time_and_frequency(text)
            if extracted_time:
                try:
                    created = await ReminderService.create_reminder(
                        user=user,
                        payload=ReminderCreate(time_of_day=extracted_time, frequency=freq),
                    )
                    reply = (
                        f"I have scheduled your {freq} weather reminder for **{created.time_of_day}**. "
                        f"At that time, you'll receive a spoken-style weather briefing. "
                        f"(Note: push delivery is currently logged and not yet wired to FCM)."
                    )
                    return ChatMessageResponse(
                        reply=reply,
                        intent="reminder",
                        reminder_created=True,
                        reminder_details=created.model_dump(),
                        suggested_actions=["Today's weather", "AQI right now", "List reminders"],
                    )
                except Exception as exc:
                    logger.warning("Failed to auto-create reminder from chat: %s", exc)
                    return ChatMessageResponse(
                        reply=f"I understood you want a reminder at {extracted_time}, but encountered an error saving it: {exc}",
                        intent="reminder",
                        suggested_actions=["Try setting a reminder again", "Today's weather"],
                    )
            else:
                return ChatMessageResponse(
                    reply=(
                        "I'd be glad to set a weather reminder for you! "
                        "What time would you like to receive it (e.g., *7:00 AM*) and how often (*daily* or *once*)?"
                    ),
                    intent="reminder",
                    suggested_actions=["Remind me daily at 7am", "Remind me at 8:00 AM once", "Today's weather"],
                )

        # 2. Weather & AQI Query Intent
        lat = payload.resolved_lat if payload.resolved_lat is not None else _DEFAULT_LAT
        lon = payload.resolved_lon if payload.resolved_lon is not None else _DEFAULT_LON

        weather = await WeatherService.get_current_weather(lat, lon)
        aqi = await AQIService.get_current_aqi(lat, lon)

        temp = round(weather.temperature_celsius)
        feels_like = round(weather.feels_like_celsius) if weather.feels_like_celsius is not None else temp
        loc_name = weather.location or "your location"
        condition = weather.condition or "Clear"
        humidity = weather.humidity_percent
        wind_kmh = round(weather.wind_speed_kmh) if weather.wind_speed_kmh is not None else 0
        uv = weather.uv_index if weather.uv_index is not None else 0.0
        aqi_val = aqi.aqi_value
        aqi_cat = aqi.category

        # Construct factual natural language response using REAL fetched data
        # Query specific customisations
        if any(w in lower_text for w in ["aqi", "air quality", "pollution", "smog"]):
            reply = (
                f"In **{loc_name}**, the Air Quality Index is currently **{aqi_val} ({aqi_cat})**. "
                f"Current temperature is **{temp}°C** with **{condition.lower()}** skies. "
                + ("Sensitive individuals may want to wear an N95 mask outdoors." if aqi_val > 100 else "Air quality is good for outdoor activities.")
            )
        elif any(w in lower_text for w in ["rain", "umbrella", "shower"]):
            rain_mm = weather.rain_mm_1h or 0.0
            is_rainy = rain_mm > 0 or "rain" in condition.lower() or "drizzle" in condition.lower()
            if is_rainy:
                reply = (
                    f"It's currently **{temp}°C** with **{condition.lower()}** in **{loc_name}** ({rain_mm:.1f} mm/h). "
                    f"Yes, you should definitely carry an umbrella today!"
                )
            else:
                reply = (
                    f"There is no heavy rain reported right now in **{loc_name}**. "
                    f"Conditions are **{condition.lower()}** at **{temp}°C** (feels like {feels_like}°C), with humidity at {humidity}%. "
                    f"You likely don't need an umbrella right now."
                )
        elif any(w in lower_text for w in ["forecast", "tomorrow", "weekend"]):
            try:
                forecast_res = await WeatherService.get_forecast(lat, lon)
                daily = forecast_res.forecast
                if len(daily) > 1:
                    tmrw = daily[1]
                    reply = (
                        f"Looking ahead for **{loc_name}**: tomorrow ({tmrw.day}) will bring **{tmrw.condition.lower()}** "
                        f"with a high of **{round(tmrw.high_celsius)}°C** and a low of **{round(tmrw.low_celsius)}°C**. "
                        f"Right now it is **{temp}°C** and **{condition.lower()}** with AQI at **{aqi_val} ({aqi_cat})**."
                    )
                else:
                    reply = (
                        f"In **{loc_name}**, current conditions are **{temp}°C** and **{condition.lower()}**. "
                        f"Humidity is {humidity}%, winds at {wind_kmh} km/h, and AQI is {aqi_val} ({aqi_cat})."
                    )
            except Exception:
                reply = (
                    f"In **{loc_name}**, current conditions are **{temp}°C** and **{condition.lower()}**. "
                    f"AQI is at **{aqi_val} ({aqi_cat})** with humidity at {humidity}%."
                )
        else:
            # General / Today's weather query
            reply = (
                f"It's **{temp}°C** and **{condition.lower()}** in **{loc_name}** right now, "
                f"with AQI at **{aqi_val} ({aqi_cat})**. "
                f"It feels like {feels_like}°C with humidity at {humidity}% and wind at {wind_kmh} km/h."
            )

        weather_snapshot = {
            "location": loc_name,
            "temperature_celsius": temp,
            "feels_like_celsius": feels_like,
            "condition": condition,
            "humidity_percent": humidity,
            "wind_speed_kmh": wind_kmh,
            "uv_index": uv,
            "aqi": aqi_val,
            "aqi_category": aqi_cat,
        }

        return ChatMessageResponse(
            reply=reply,
            intent="weather",
            weather_data=weather_snapshot,
            suggested_actions=["Today's weather", "Remind me daily at 7am", "AQI right now"],
        )
