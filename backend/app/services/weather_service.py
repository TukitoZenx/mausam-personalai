"""
Weather service — fetches real data from OpenWeatherMap via adapter, with:
  - Redis-backed caching (10 min TTL for current, 30 min for forecast)
  - Stale-cache fallback when the upstream call fails
  - Clean 503 ExternalServiceException when no cache exists at all
"""

import json
import logging

from app.core.exceptions import ExternalServiceException
from app.redis_client import redis_client
from app.schemas.weather import CurrentWeather, ForecastResponse
from app.services.adapters import openweather_adapter as owm

logger = logging.getLogger(__name__)

# Cache TTLs (seconds)
_TTL_CURRENT = 600   # 10 minutes
_TTL_FORECAST = 1800  # 30 minutes

# Cache key helpers
def _key_current(lat: float, lon: float) -> str:
    return f"weather:current:{lat}:{lon}"

def _key_forecast(lat: float, lon: float) -> str:
    return f"weather:forecast:{lat}:{lon}"


class WeatherService:

    @staticmethod
    async def get_current_weather(lat: float, lon: float) -> CurrentWeather:
        cache_key = _key_current(lat, lon)

        # --- Try cache hit ---
        cached_raw = await redis_client.get(cache_key)
        if cached_raw:
            data = json.loads(cached_raw)
            data["cached"] = True
            data["stale"] = False
            logger.info("Cache HIT: %s", cache_key)
            return CurrentWeather(**data)

        # --- Cache miss: fetch from OWM ---
        logger.info("Cache MISS: %s — fetching from OpenWeatherMap", cache_key)
        try:
            raw_current = await owm.fetch_current_weather(lat, lon)
            try:
                uvi = await owm.fetch_uvi(lat, lon)
            except ExternalServiceException:
                logger.warning("UVI fetch failed for %s — uv_index will be 0.0", cache_key)
                uvi = 0.0

            result = owm.normalize_current_weather(raw_current, uvi=uvi)
            result.cached = False
            result.stale = False

            # Cache the result (store without cached/stale flags)
            payload = result.model_dump()
            payload.pop("cached", None)
            payload.pop("stale", None)
            serialized = json.dumps(payload)
            await redis_client.setex(cache_key, _TTL_CURRENT, serialized)
            # Shadow stale backup — no TTL; survives cache expiry for fallback
            await redis_client.set(f"stale:{cache_key}", serialized)

            return result

        except ExternalServiceException as exc:
            # Upstream failed — try stale cache (no TTL check, raw get bypasses expiry)
            stale_raw = await _get_stale(cache_key)
            if stale_raw:
                data = json.loads(stale_raw)
                data["cached"] = False
                data["stale"] = True
                logger.warning("Returning STALE cache for %s due to upstream failure: %s", cache_key, exc)
                return CurrentWeather(**data)
            # No stale cache either — propagate 503
            raise

    @staticmethod
    async def get_forecast(lat: float, lon: float) -> ForecastResponse:
        cache_key = _key_forecast(lat, lon)

        # --- Try cache hit ---
        cached_raw = await redis_client.get(cache_key)
        if cached_raw:
            data = json.loads(cached_raw)
            data["cached"] = True
            data["stale"] = False
            logger.info("Cache HIT: %s", cache_key)
            return ForecastResponse(**data)

        # --- Cache miss: fetch from OWM ---
        logger.info("Cache MISS: %s — fetching from OpenWeatherMap", cache_key)
        try:
            raw_current, raw_forecast = await _fetch_both(lat, lon)
            result = owm.normalize_forecast(raw_current, raw_forecast)
            result.cached = False
            result.stale = False

            payload = result.model_dump()
            payload.pop("cached", None)
            payload.pop("stale", None)
            serialized = json.dumps(payload)
            await redis_client.setex(cache_key, _TTL_FORECAST, serialized)
            # Shadow stale backup — no TTL; survives cache expiry for fallback
            await redis_client.set(f"stale:{cache_key}", serialized)

            return result

        except ExternalServiceException as exc:
            stale_raw = await _get_stale(cache_key)
            if stale_raw:
                data = json.loads(stale_raw)
                data["cached"] = False
                data["stale"] = True
                logger.warning("Returning STALE cache for %s due to upstream failure: %s", cache_key, exc)
                return ForecastResponse(**data)
            raise


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

async def _fetch_both(lat: float, lon: float):
    """Fetch current + 5-day forecast (OWM 2.5 free tier)."""
    raw_current = await owm.fetch_current_weather(lat, lon)
    raw_forecast = await owm.fetch_forecast_daily(lat, lon)
    return raw_current, raw_forecast


async def _get_stale(cache_key: str):
    """
    Retrieve a value from Redis even if it has been logically marked stale.
    Because we use SETEX (hard TTL), a truly expired key won't be returned.
    To support stale-on-failure, we maintain a shadow key without TTL
    (prefixed `stale:`) updated on each successful fetch.
    """
    return await redis_client.get(f"stale:{cache_key}")
