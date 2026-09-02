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
import math
from datetime import datetime, timezone, timedelta
from typing import Any

import httpx

from app.core.config import settings
from app.core.exceptions import ExternalServiceException
from app.schemas.aqi import AQIResponse
from app.schemas.weather import (
    CurrentWeather,
    DailyForecastItem,
    ForecastResponse,
    HourlyForecastItem,
)

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


async def fetch_uvi(lat: float, lon: float) -> float:
    """Fetch current UV index from OWM 2.5 UVI endpoint."""
    url = f"{OWM_BASE}/data/2.5/uvi"
    params = {"lat": lat, "lon": lon, "appid": settings.WEATHER_API_KEY}
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(url, params=params)
        if response.status_code != 200:
            logger.error("OWM uvi non-200: %d — %s", response.status_code, response.text[:200])
            raise ExternalServiceException(
                f"OpenWeatherMap UVI returned HTTP {response.status_code}"
            )
        payload = response.json()
        return round(float(payload.get("value", 0.0)), 2)
    except httpx.TimeoutException as exc:
        logger.error("OWM uvi timed out: %s", exc)
        raise ExternalServiceException("OpenWeatherMap UVI request timed out") from exc
    except ExternalServiceException:
        raise
    except Exception as exc:
        logger.error("OWM uvi unexpected error: %s", exc)
        raise ExternalServiceException("Unexpected error fetching UVI") from exc


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

def _kelvin_to_celsius(k: float | None) -> float | None:
    if k is None:
        return None
    return round(float(k) - 273.15, 2)


def _ms_to_kmh(ms: float) -> float:
    return round(ms * 3.6, 2)


def _precip_mm(block: dict[str, Any] | None) -> float | None:
    if not isinstance(block, dict):
        return None
    if "1h" in block:
        return round(float(block["1h"]), 2)
    if "3h" in block:
        return round(float(block["3h"]), 2)
    return None


def _dew_point_celsius(temp_c: float, humidity: int) -> float:
    a = 17.27
    b = 237.7
    rh = max(min(humidity, 100), 1) / 100.0
    gamma = (a * temp_c) / (b + temp_c) + math.log(rh)
    return round((b * gamma) / (a - gamma), 2)


def _moon_phase_fraction(dt: datetime) -> float:
    """Synodic-month fraction since known new moon 2000-01-06 18:14 UTC."""
    known_new = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc)
    synodic = 29.53058867
    days = (dt - known_new).total_seconds() / 86400.0
    return round(days / synodic % 1.0, 4)


def _approx_moon_times(sunrise: int | None, sunset: int | None, phase: float) -> tuple[int | None, int | None]:
    """Approximate moonrise/moonset from sunrise/sunset + phase (One Call is unauthorized)."""
    if sunrise is None or sunset is None:
        return None, None
    day = 86400
    return int(sunrise + phase * day), int(sunset + phase * day)


def _icon_from(weather_list: list | None) -> str | None:
    if not weather_list:
        return None
    return weather_list[0].get("icon")


def _condition_from(weather_list: list | None) -> str:
    if not weather_list:
        return "Unknown"
    return str(weather_list[0].get("description", "Unknown")).title()


def normalize_current_weather(
    raw: dict[str, Any],
    uvi: float = 0.0,
    dew_point_celsius: float | None = None,
    high_celsius: float | None = None,
    low_celsius: float | None = None,
) -> CurrentWeather:
    """Normalize OWM /data/2.5/weather into CurrentWeather, including extra current fields."""
    main = raw.get("main") or {}
    wind = raw.get("wind") or {}
    sys = raw.get("sys") or {}
    weather_list = raw.get("weather") or []
    temp_c = _kelvin_to_celsius(main.get("temp")) or 0.0
    humidity = int(main.get("humidity", 0))
    feels = _kelvin_to_celsius(main.get("feels_like"))
    visibility_m = raw.get("visibility")
    rain = raw.get("rain") if isinstance(raw.get("rain"), dict) else {}
    snow = raw.get("snow") if isinstance(raw.get("snow"), dict) else {}
    dew = dew_point_celsius
    if dew is None and humidity:
        dew = _dew_point_celsius(temp_c, humidity)

    return CurrentWeather(
        location=raw.get("name", "Unknown"),
        temperature_celsius=temp_c,
        condition=_condition_from(weather_list),
        condition_icon=_icon_from(weather_list),
        humidity_percent=humidity,
        dew_point_celsius=dew,
        wind_speed_kmh=_ms_to_kmh(float(wind.get("speed", 0.0))),
        wind_direction_deg=float(wind["deg"]) if wind.get("deg") is not None else None,
        pressure_hpa=float(main["pressure"]) if main.get("pressure") is not None else None,
        uv_index=round(uvi, 2),
        feels_like_celsius=feels,
        high_celsius=high_celsius if high_celsius is not None else _kelvin_to_celsius(main.get("temp_max")),
        low_celsius=low_celsius if low_celsius is not None else _kelvin_to_celsius(main.get("temp_min")),
        visibility_km=round(float(visibility_m) / 1000.0, 2) if visibility_m is not None else None,
        rain_mm_1h=round(float(rain["1h"]), 2) if rain.get("1h") is not None else None,
        rain_mm_3h=round(float(rain["3h"]), 2) if rain.get("3h") is not None else None,
        snow_mm_1h=round(float(snow["1h"]), 2) if snow.get("1h") is not None else None,
        sunrise_unix=int(sys["sunrise"]) if sys.get("sunrise") is not None else None,
        sunset_unix=int(sys["sunset"]) if sys.get("sunset") is not None else None,
        timezone_offset_sec=int(raw["timezone"]) if raw.get("timezone") is not None else None,
        observed_at_unix=int(raw["dt"]) if raw.get("dt") is not None else None,
    )


def normalize_forecast(
    raw_current: dict[str, Any],
    raw_forecast: dict[str, Any],
    uvi: float = 0.0,
) -> ForecastResponse:
    """
    Normalize OWM current + 2.5 /forecast (3-hour intervals) into ForecastResponse.

    One Call 3.0 is unauthorized on this key, so hourly entries are the 3-hour
    forecast slots. Moon phase is computed from date; moonrise/moonset are
    approximated from sunrise/sunset + phase. Last-24h precipitation is not
    present on the 2.5 current endpoint.
    """
    tz_offset = int(raw_current.get("timezone") or (raw_forecast.get("city") or {}).get("timezone") or 0)
    tzinfo = timezone(timedelta(seconds=tz_offset))

    hourly: list[HourlyForecastItem] = []
    daily_buckets: dict[str, dict] = {}
    precip_next_24h = 0.0
    nearest_dew: float | None = None

    for idx, slot in enumerate(raw_forecast.get("list", [])):
        dt_unix = int(slot.get("dt") or 0)
        local_dt = datetime.fromtimestamp(dt_unix, tz=tzinfo)
        main = slot.get("main") or {}
        temp_c = _kelvin_to_celsius(main.get("temp")) or 0.0
        rain_mm = _precip_mm(slot.get("rain")) or _precip_mm(slot.get("snow"))
        pop = int(round(float(slot.get("pop") or 0.0) * 100))
        wind = slot.get("wind") or {}
        if nearest_dew is None and main.get("dew_point") is not None:
            nearest_dew = _kelvin_to_celsius(main.get("dew_point"))

        hourly.append(
            HourlyForecastItem(
                dt_unix=dt_unix,
                hour_label=local_dt.strftime("%H:%M"),
                temperature_celsius=temp_c,
                condition=_condition_from(slot.get("weather")),
                condition_icon=_icon_from(slot.get("weather")),
                rain_probability_percent=pop,
                rain_mm=rain_mm,
                wind_speed_kmh=_ms_to_kmh(float(wind.get("speed", 0.0))),
                wind_direction_deg=float(wind["deg"]) if wind.get("deg") is not None else None,
            )
        )
        if idx < 8 and rain_mm:
            precip_next_24h += rain_mm

        date_str = local_dt.strftime("%Y-%m-%d")
        if date_str not in daily_buckets:
            daily_buckets[date_str] = {
                "temps_max": [],
                "temps_min": [],
                "conditions": [],
                "icons": [],
                "pops": [],
                "rain": [],
            }
        daily_buckets[date_str]["temps_max"].append(main.get("temp_max", main.get("temp")))
        daily_buckets[date_str]["temps_min"].append(main.get("temp_min", main.get("temp")))
        daily_buckets[date_str]["conditions"].append(_condition_from(slot.get("weather")))
        daily_buckets[date_str]["icons"].append(_icon_from(slot.get("weather")))
        daily_buckets[date_str]["pops"].append(slot.get("pop", 0.0))
        if rain_mm:
            daily_buckets[date_str]["rain"].append(rain_mm)

    city = raw_forecast.get("city") or {}
    sunrise = city.get("sunrise") or (raw_current.get("sys") or {}).get("sunrise")
    sunset = city.get("sunset") or (raw_current.get("sys") or {}).get("sunset")
    sunrise_i = int(sunrise) if sunrise is not None else None
    sunset_i = int(sunset) if sunset is not None else None

    daily_items: list[DailyForecastItem] = []
    for date_str, bucket in list(daily_buckets.items())[:7]:
        dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=tzinfo)
        phase = _moon_phase_fraction(dt)
        moonrise, moonset = _approx_moon_times(sunrise_i, sunset_i, phase)
        midday_idx = len(bucket["conditions"]) // 2
        rain_total = round(sum(bucket["rain"]), 2) if bucket["rain"] else None
        daily_items.append(
            DailyForecastItem(
                day=dt.strftime("%A"),
                weekday=dt.strftime("%a"),
                date=date_str,
                high_celsius=_kelvin_to_celsius(max(bucket["temps_max"])) or 0.0,
                low_celsius=_kelvin_to_celsius(min(bucket["temps_min"])) or 0.0,
                condition=bucket["conditions"][midday_idx],
                condition_icon=bucket["icons"][midday_idx],
                rain_probability_percent=round(max(bucket["pops"]) * 100),
                rain_mm=rain_total,
                moon_phase=phase,
                moonrise_unix=moonrise,
                moonset_unix=moonset,
            )
        )

    today_high = daily_items[0].high_celsius if daily_items else None
    today_low = daily_items[0].low_celsius if daily_items else None
    current = normalize_current_weather(
        raw_current,
        uvi=uvi,
        dew_point_celsius=nearest_dew,
        high_celsius=today_high,
        low_celsius=today_low,
    )

    return ForecastResponse(
        location=raw_current.get("name") or city.get("name") or "Unknown",
        current=current,
        hourly=hourly,
        forecast=daily_items,
        precip_next_24h_mm=round(precip_next_24h, 2),
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
