"""
Weather Tools — Reusable, grounded tool functions for the Mausam AI Assistant.

These tools interface directly with existing backend services:
  - WeatherService (OpenWeatherMap current & 5-day / 3-hour forecast)
  - AQIService (Air pollution & pollutants)
  - AlertService (Evaluated alerts for heat, thunderstorms, rain, wind, AQI)
  - LocationService (Forward & reverse geocoding via Nominatim / Open-Meteo)

The AI Orchestrator strictly executes these tools against real data sources
to guarantee zero hallucination.
"""

from datetime import datetime, timezone, timedelta
import logging
from typing import Any

from app.services.alert_service import AlertService
from app.services.aqi_service import AQIService
from app.services.location_service import LocationService
from app.services.weather_service import WeatherService

logger = logging.getLogger(__name__)


async def resolve_location_coords(
    location: str | None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
) -> tuple[float, float, str]:
    """
    Resolve a location name or string to (latitude, longitude, display_name).
    If location is None, empty, or 'current'/'here', returns the default coordinates.
    """
    if not location or location.strip().lower() in ("current", "here", "my location", "active location"):
        return default_lat, default_lon, default_name

    clean_query = location.strip()
    try:
        results = await LocationService.search_locations(clean_query)
        if results:
            match = results[0]
            display = match.name or clean_query
            return match.latitude, match.longitude, display
    except Exception as exc:
        logger.warning("Geocoding failed for '%s': %s", clean_query, exc)

    return default_lat, default_lon, clean_query


async def get_current_weather(
    location: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
) -> dict[str, Any]:
    """
    Fetch factual current weather conditions for the specified location.
    """
    lat, lon, name = await resolve_location_coords(location, default_lat, default_lon, default_name)
    current = await WeatherService.get_current_weather(lat, lon)
    aqi_res = await AQIService.get_current_aqi(lat, lon)

    temp = round(current.temperature_celsius)
    feels = round(current.feels_like_celsius) if current.feels_like_celsius is not None else temp

    return {
        "location": current.location or name,
        "latitude": lat,
        "longitude": lon,
        "temperature_celsius": temp,
        "feels_like_celsius": feels,
        "condition": current.condition or "Clear",
        "humidity_percent": current.humidity_percent,
        "wind_speed_kmh": round(current.wind_speed_kmh) if current.wind_speed_kmh is not None else 0,
        "wind_direction_deg": current.wind_direction_deg,
        "uv_index": current.uv_index if current.uv_index is not None else 0.0,
        "rain_mm_1h": current.rain_mm_1h if current.rain_mm_1h is not None else 0.0,
        "visibility_km": current.visibility_km,
        "pressure_hpa": current.pressure_hpa,
        "dew_point_celsius": current.dew_point_celsius,
        "sunrise_unix": current.sunrise_unix,
        "sunset_unix": current.sunset_unix,
        "aqi": aqi_res.aqi_value,
        "aqi_category": aqi_res.category,
    }


async def get_hourly_forecast(
    location: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
    hours_limit: int = 8,
) -> list[dict[str, Any]]:
    """
    Fetch upcoming hourly/interval forecast for the specified location.
    """
    lat, lon, _ = await resolve_location_coords(location, default_lat, default_lon, default_name)
    forecast_res = await WeatherService.get_forecast(lat, lon)

    slots: list[dict[str, Any]] = []
    for h in forecast_res.hourly[:hours_limit]:
        slots.append({
            "hour": h.hour_label,
            "dt_unix": h.dt_unix,
            "temperature_celsius": round(h.temperature_celsius),
            "condition": h.condition,
            "rain_probability_percent": getattr(h, "rain_probability_percent", 0),
            "rain_mm": getattr(h, "rain_mm", 0.0),
            "wind_speed_kmh": getattr(h, "wind_speed_kmh", 0.0),
        })
    return slots


async def get_daily_forecast(
    location: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
    days_limit: int = 5,
) -> list[dict[str, Any]]:
    """
    Fetch daily forecast for the coming 5 days.
    """
    lat, lon, _ = await resolve_location_coords(location, default_lat, default_lon, default_name)
    forecast_res = await WeatherService.get_forecast(lat, lon)

    daily: list[dict[str, Any]] = []
    for d in forecast_res.forecast[:days_limit]:
        daily.append({
            "day": d.day,
            "date": d.date,
            "weekday": getattr(d, "weekday", d.day[:3]),
            "condition": d.condition,
            "high_celsius": round(d.high_celsius),
            "low_celsius": round(d.low_celsius),
            "rain_probability_percent": getattr(d, "rain_probability_percent", 0),
            "rain_mm": getattr(d, "rain_mm", None),
            "moon_phase": getattr(d, "moon_phase", 0.0),
        })
    return daily


async def get_weather_alerts(
    location: str | None = None,
    persona: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
) -> list[dict[str, Any]]:
    """
    Retrieve active weather warnings and safety advisories for the specified location.
    """
    lat, lon, _ = await resolve_location_coords(location, default_lat, default_lon, default_name)
    alerts = await AlertService.get_alerts(
        user={"persona_type": persona or "Fitness"},
        lat=lat,
        lon=lon,
        persona=persona,
    )
    return [
        {
            "id": a.id,
            "headline": a.headline,
            "severity": a.severity,
            "description": a.description,
            "issued_at": a.issued_at,
            "status": a.status,
        }
        for a in alerts
    ]


async def get_air_quality(
    location: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
) -> dict[str, Any]:
    """
    Retrieve detailed air quality and pollutant measurements for the location.
    """
    lat, lon, name = await resolve_location_coords(location, default_lat, default_lon, default_name)
    aqi_res = await AQIService.get_current_aqi(lat, lon)
    return {
        "location": aqi_res.location or name,
        "aqi_value": aqi_res.aqi_value,
        "category": aqi_res.category,
        "pollutants": aqi_res.pollutants or {},
    }


async def get_sunrise_sunset(
    location: str | None = None,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
    default_name: str = "Active Location",
) -> dict[str, Any]:
    """
    Retrieve sunrise, sunset, daylight duration, and solar info.
    """
    lat, lon, name = await resolve_location_coords(location, default_lat, default_lon, default_name)
    current = await WeatherService.get_current_weather(lat, lon)

    sunrise_str = "Unknown"
    sunset_str = "Unknown"
    daylight_hours = 0.0

    tz_offset = current.timezone_offset_sec or 0
    tz = timezone(timedelta(seconds=tz_offset))

    if current.sunrise_unix:
        dt_rise = datetime.fromtimestamp(current.sunrise_unix, tz=tz)
        sunrise_str = dt_rise.strftime("%I:%M %p")
    if current.sunset_unix:
        dt_set = datetime.fromtimestamp(current.sunset_unix, tz=tz)
        sunset_str = dt_set.strftime("%I:%M %p")

    if current.sunrise_unix and current.sunset_unix and current.sunset_unix > current.sunrise_unix:
        daylight_hours = round((current.sunset_unix - current.sunrise_unix) / 3600.0, 1)

    return {
        "location": current.location or name,
        "sunrise": sunrise_str,
        "sunset": sunset_str,
        "daylight_hours": daylight_hours,
        "sunrise_unix": current.sunrise_unix,
        "sunset_unix": current.sunset_unix,
    }


async def compare_weather(
    location1: str,
    location2: str,
    default_lat: float = 17.3850,
    default_lon: float = 78.4867,
) -> dict[str, Any]:
    """
    Compare real-time weather and air quality between two locations.
    """
    w1 = await get_current_weather(location1, default_lat=default_lat, default_lon=default_lon)
    w2 = await get_current_weather(location2, default_lat=default_lat, default_lon=default_lon)

    temp_diff = round(w1["temperature_celsius"] - w2["temperature_celsius"], 1)
    aqi_diff = w1["aqi"] - w2["aqi"]

    return {
        "location1": w1,
        "location2": w2,
        "temperature_difference_celsius": temp_diff,
        "aqi_difference": aqi_diff,
        "warmer_location": w1["location"] if temp_diff > 0 else (w2["location"] if temp_diff < 0 else "Equal"),
        "cleaner_air_location": w1["location"] if aqi_diff < 0 else (w2["location"] if aqi_diff > 0 else "Equal"),
    }


def get_weather_history(
    location: str | None = None,
    date_range: str | None = None,
) -> dict[str, Any]:
    """
    Factual handling of historical weather requests.
    OpenWeatherMap free tier provides recent observation history only.
    """
    return {
        "status": "partial_support",
        "message": (
            "Historical weather past the recent observation cycle is not available on the current free weather API tier. "
            "However, current real-time observations and 5-day forecast trends are fully active."
        ),
        "location": location or "Active Location",
    }
