"""
Nominatim OpenStreetMap reverse geocoding adapter.
Fetches place name, city, and state/region for given lat/lon coordinates.
"""

import logging
from typing import Any

import httpx

from app.core.exceptions import ExternalServiceException
from app.schemas.location import LocationInfo

logger = logging.getLogger(__name__)

NOMINATIM_BASE = "https://nominatim.openstreetmap.org"
TIMEOUT = httpx.Timeout(5.0)
USER_AGENT = "MausamPersonalAI/1.0 (contact@mausam.ai)"


async def reverse_geocode(lat: float, lon: float) -> LocationInfo:
    """
    Reverse geocode lat/lon to LocationInfo via Nominatim OSM API.
    Raises ExternalServiceException on network error, non-200, or timeout.
    """
    url = f"{NOMINATIM_BASE}/reverse"
    params = {
        "lat": lat,
        "lon": lon,
        "format": "json",
        "zoom": 10,
        "addressdetails": 1,
    }
    headers = {"User-Agent": USER_AGENT}

    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            response = await client.get(url, params=params, headers=headers)

        if response.status_code != 200:
            logger.error("Nominatim non-200: %d — %s", response.status_code, response.text[:200])
            raise ExternalServiceException(
                f"Nominatim reverse geocode returned HTTP {response.status_code}"
            )

        data: dict[str, Any] = response.json()
        address = data.get("address", {})

        place_name = data.get("display_name", f"{lat:.4f}, {lon:.4f}")
        city = (
            address.get("city")
            or address.get("town")
            or address.get("village")
            or address.get("county")
            or ""
        )
        state_region = address.get("state") or address.get("region") or address.get("country") or ""

        # Format a cleaner place_name if city and state exist
        if city and state_region:
            short_name = f"{city}, {state_region}"
        elif city:
            short_name = city
        else:
            short_name = place_name.split(",")[0]

        return LocationInfo(
            latitude=lat,
            longitude=lon,
            place_name=short_name,
            city=city,
            state_region=state_region,
            cached=False,
            stale=False,
        )

    except httpx.TimeoutException as exc:
        logger.error("Nominatim reverse geocode timed out: %s", exc)
        raise ExternalServiceException("Nominatim reverse geocoding request timed out") from exc
    except ExternalServiceException:
        raise
    except Exception as exc:
        logger.error("Nominatim reverse geocode error: %s", exc)
        raise ExternalServiceException("Unexpected error during reverse geocoding") from exc
