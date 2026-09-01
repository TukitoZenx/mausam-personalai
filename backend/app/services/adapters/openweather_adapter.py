"""
OpenWeatherMap adapter — fetch + normalize raw OWM responses into internal Pydantic schemas.

Field Mapping (OWM → internal schema):
  Current Weather:
    main.temp          → temperature_celsius   (Kelvin → Celsius: K - 273.15)
    weather[0].description → condition
    main.humidity      → humidity_percent
    wind.speed * 3.6   → wind_speed_kmh        (m/s → km/h)
    uvi (from onecall) → uv_index              (fallback 0.0 for basic endpoint)
    name               → location

  Forecast (One Call daily[]):
    daily[i].summary / weather[0].description → condition
    daily[i].temp.max  → high_celsius
    daily[i].temp.min  → low_celsius
    daily[i].pop * 100 → rain_probability_percent  (0-1 → 0-100)
    dt (epoch)         → day                    (formatted weekday name)

  AQI (Air Pollution API):
    list[0].main.aqi   → aqi_value             (OWM scale 1-5 → mapped to US AQI equivalent)
    list[0].components.pm2_5 → pollutants.pm2_5
    list[0].components.pm10  → pollutants.pm10
    list[0].components.o3    → pollutants.o3
    list[0].components.no2   → pollutants.no2
    list[0].components.so2   → pollutants.so2
    list[0].components.co    → pollutants.co
"""

import logging
from datetime import datetime, timezone
from typing import Any

import httpx

from app.core.config import settings
from app.core.exceptions import ExternalServiceException
from app.schemas.aqi import AQIResponse
from app.schemas.weather import CurrentWeather, DailyForecastItem, ForecastResponse

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
OWM_BASE = "https://api.openweathermap.org"
TIMEOUT = httpx.Timeout(5.0)  # 5-second hard timeout on all outbound calls

# OWM AQI scale (1-5) → approximate US AQI midpoint values
_OWM_AQI_MAP = {1: 25, 2: 75, 3: 125, 4: 200, 5: 300}
_OWM_AQI_CATEGORY = {
    1: "Good",
    2: "Fair",
    3: "Moderate",
    4: "Poor",
    5: "Very Poor",
}


# ---------------------------------------------------------------------------
# Fetch helpers — raise ExternalServiceException on any failure
# ---------------------------------------------------------------------------

async def fetch_current_weather(lat: float, lon: float) -> dict[str, Any]:
    """Fetch raw current weather from OWM Current Weather API."""
    url = f"{OWM_BASE}/data/2.5/weather"
    params = {"lat": lat, "lon": lon, "appid": settings.WEATHER_API_KEY}
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(url, params=params)
        if response.status_code != 200:
            logger.error("OWM current weather non-200: %d — %s", response.status_code, response.text[:200])
            raise ExternalServiceException(
                f"OpenWeatherMap current weather returned HTTP {response.status_code}"
            )
        return response.json()
    except httpx.TimeoutException as exc:
        logger.error("OWM current weather timed out: %s", exc)
        raise ExternalServiceException("OpenWeatherMap current weather request timed out") from exc
    except ExternalServiceException:
        raise
    except Exception as exc:
        logger.error("OWM current weather unexpected error: %s", exc)
        raise ExternalServiceException("Unexpected error fetching current weather") from exc


async def fetch_forecast_daily(lat: float, lon: float) -> dict[str, Any]:
    """Fetch raw 5-day/3-hour forecast from OWM Free 2.5 endpoint."""
    url = f"{OWM_BASE}/data/2.5/forecast"
    params = {
        "lat": lat,
        "lon": lon,
        "appid": settings.WEATHER_API_KEY,
        "cnt": 40,  # max 40 intervals = ~5 days
    }
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(url, params=params)
        if response.status_code != 200:
            logger.error("OWM forecast non-200: %d — %s", response.status_code, response.text[:200])
            raise ExternalServiceException(
                f"OpenWeatherMap forecast returned HTTP {response.status_code}"
            )
        return response.json()
    except httpx.TimeoutException as exc:
        logger.error("OWM forecast timed out: %s", exc)
        raise ExternalServiceException("OpenWeatherMap forecast request timed out") from exc
    except ExternalServiceException:
        raise
    except Exception as exc:
        logger.error("OWM forecast unexpected error: %s", exc)
        raise ExternalServiceException("Unexpected error fetching forecast") from exc


async def fetch_air_pollution(lat: float, lon: float) -> dict[str, Any]:
    """Fetch raw Air Pollution API data from OWM."""
    url = f"{OWM_BASE}/data/2.5/air_pollution"
    params = {"lat": lat, "lon": lon, "appid": settings.WEATHER_API_KEY}
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(url, params=params)
        if response.status_code != 200:
            logger.error("OWM air pollution non-200: %d — %s", response.status_code, response.text[:200])
            raise ExternalServiceException(
                f"OpenWeatherMap Air Pollution returned HTTP {response.status_code}"
            )
        return response.json()
    except httpx.TimeoutException as exc:
        logger.error("OWM air pollution timed out: %s", exc)
        raise ExternalServiceException("OpenWeatherMap AQI request timed out") from exc
    except ExternalServiceException:
        raise
    except Exception as exc:
        logger.error("OWM air pollution unexpected error: %s", exc)
        raise ExternalServiceException("Unexpected error fetching AQI data") from exc


# ---------------------------------------------------------------------------
# Normalization helpers — convert raw OWM JSON → internal Pydantic schemas
# ---------------------------------------------------------------------------

def _kelvin_to_celsius(k: float) -> float:
    return round(k - 273.15, 2)


def _ms_to_kmh(ms: float) -> float:
    return round(ms * 3.6, 2)


def normalize_current_weather(raw: dict[str, Any], uvi: float = 0.0) -> CurrentWeather:
    """
    Normalize OWM /data/2.5/weather response into CurrentWeather schema.
    uvi is passed from onecall if available (not in basic endpoint).
    """
    return CurrentWeather(
        location=raw.get("name", "Unknown"),
        temperature_celsius=_kelvin_to_celsius(raw["main"]["temp"]),
        condition=raw["weather"][0]["description"].title(),
        humidity_percent=int(raw["main"]["humidity"]),
        wind_speed_kmh=_ms_to_kmh(raw["wind"].get("speed", 0.0)),
        uv_index=round(uvi, 2),
    )


def normalize_forecast(raw_current: dict[str, Any], raw_forecast: dict[str, Any]) -> ForecastResponse:
    """
    Normalize OWM current + 2.5 /forecast (3-hour intervals) into ForecastResponse schema.
    Groups 3-hour intervals by UTC date to produce daily items (up to 5 days).

    OWM 2.5 /forecast field mapping:
      list[i].main.temp_max   → high_celsius  (Kelvin → Celsius)
      list[i].main.temp_min   → low_celsius
      list[i].weather[0].description → condition
      list[i].pop             → rain_probability_percent (0-1 → 0-100)
      list[i].dt_txt          → day (parsed date, formatted as weekday)
    """
    current = normalize_current_weather(raw_current, uvi=0.0)  # uvi needs paid tier

    # Aggregate 3-hour slots into daily buckets
    daily_buckets: dict[str, dict] = {}
    for slot in raw_forecast.get("list", []):
        date_str = slot["dt_txt"][:10]  # "YYYY-MM-DD"
        if date_str not in daily_buckets:
            daily_buckets[date_str] = {
                "temps_max": [],
                "temps_min": [],
                "conditions": [],
                "pops": [],
            }
        daily_buckets[date_str]["temps_max"].append(slot["main"]["temp_max"])
        daily_buckets[date_str]["temps_min"].append(slot["main"]["temp_min"])
        daily_buckets[date_str]["conditions"].append(
            slot["weather"][0]["description"].title() if slot.get("weather") else "Unknown"
        )
        daily_buckets[date_str]["pops"].append(slot.get("pop", 0.0))

    daily_items: list[DailyForecastItem] = []
    for date_str, bucket in list(daily_buckets.items())[:7]:
        dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        day_label = dt.strftime("%A")
        daily_items.append(
            DailyForecastItem(
                day=day_label,
                high_celsius=_kelvin_to_celsius(max(bucket["temps_max"])),
                low_celsius=_kelvin_to_celsius(min(bucket["temps_min"])),
                condition=bucket["conditions"][len(bucket["conditions"]) // 2],  # midday slot
                rain_probability_percent=round(max(bucket["pops"]) * 100),
            )
        )

    return ForecastResponse(
        location=raw_current.get("name", "Unknown"),
        current=current,
        forecast=daily_items,
    )


def normalize_aqi(raw: dict[str, Any], location: str = "Unknown") -> AQIResponse:
    """
    Normalize OWM /data/2.5/air_pollution response into AQIResponse schema.
    OWM AQI scale: 1=Good, 2=Fair, 3=Moderate, 4=Poor, 5=Very Poor.
    Mapped to approximate US AQI midpoint values.
    """
    entry = raw["list"][0]
    owm_aqi = int(entry["main"]["aqi"])
    components = entry.get("components", {})

    return AQIResponse(
        location=location,
        aqi_value=_OWM_AQI_MAP.get(owm_aqi, owm_aqi * 50),
        category=_OWM_AQI_CATEGORY.get(owm_aqi, "Unknown"),
        pollutants={
            "pm2_5": round(components.get("pm2_5", 0.0), 2),
            "pm10": round(components.get("pm10", 0.0), 2),
            "o3": round(components.get("o3", 0.0), 2),
            "no2": round(components.get("no2", 0.0), 2),
            "so2": round(components.get("so2", 0.0), 2),
            "co": round(components.get("co", 0.0), 2),
        },
    )
