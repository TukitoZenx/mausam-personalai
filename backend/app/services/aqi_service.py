"""
AQI service — fetches real data from OpenWeatherMap Air Pollution API via adapter, with:
  - Redis-backed caching (10 min TTL)
  - Stale-cache fallback when the upstream call fails
  - Clean 503 ExternalServiceException when no cache exists at all
"""

import json
import logging

from app.core.exceptions import ExternalServiceException
from app.redis_client import redis_client
from app.schemas.aqi import AQIResponse
from app.services.adapters import openweather_adapter as owm

logger = logging.getLogger(__name__)

_TTL_AQI = 600  # 10 minutes

def _key_aqi(lat: float, lon: float) -> str:
    return f"aqi:current:{lat}:{lon}"


class AQIService:

    @staticmethod
    async def get_current_aqi(lat: float, lon: float) -> AQIResponse:
        cache_key = _key_aqi(lat, lon)

        # --- Try cache hit ---
        cached_raw = await redis_client.get(cache_key)
        if cached_raw:
            data = json.loads(cached_raw)
            data["cached"] = True
            data["stale"] = False
            logger.info("Cache HIT: %s", cache_key)
            return AQIResponse(**data)

        # --- Cache miss: fetch from OWM ---
        logger.info("Cache MISS: %s — fetching from OpenWeatherMap", cache_key)
        try:
            # Fetch location name from current weather for labeling
            try:
                raw_current = await owm.fetch_current_weather(lat, lon)
                location = raw_current.get("name", f"{lat},{lon}")
            except ExternalServiceException:
                location = f"{lat},{lon}"

            raw_aqi = await owm.fetch_air_pollution(lat, lon)
            result = owm.normalize_aqi(raw_aqi, location=location)
            result.cached = False
            result.stale = False

            payload = result.model_dump()
            payload.pop("cached", None)
            payload.pop("stale", None)
            serialized = json.dumps(payload)
            await redis_client.setex(cache_key, _TTL_AQI, serialized)
            # Shadow stale backup — no TTL; survives cache expiry for fallback
            await redis_client.set(f"stale:{cache_key}", serialized)

            return result

        except ExternalServiceException as exc:
            stale_raw = await redis_client.get(f"stale:{cache_key}")
            if stale_raw:
                data = json.loads(stale_raw)
                data["cached"] = False
                data["stale"] = True
                logger.warning("Returning STALE cache for %s due to upstream failure: %s", cache_key, exc)
                return AQIResponse(**data)
            raise
