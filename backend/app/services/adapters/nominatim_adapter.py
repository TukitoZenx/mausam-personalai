"""
Nominatim & Open-Meteo geocoding adapter.
Provides reverse geocoding and forward location search.
"""

import logging
from typing import Any

import httpx

from app.core.exceptions import ExternalServiceException
from app.schemas.location import LocationInfo, LocationSearchResult

logger = logging.getLogger(__name__)

NOMINATIM_BASE = "https://nominatim.openstreetmap.org"
OPEN_METEO_GEO_BASE = "https://geocoding-api.open-meteo.com/v1/search"
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


async def search_locations(query: str) -> list[LocationSearchResult]:
    """
    Forward geocode search query (e.g. 'Hyderabad', 'Mumbai', 'Banjara Hills', 'London')
    Uses Open-Meteo Geocoding API as primary + Nominatim OSM as fallback.
    Returns list of LocationSearchResult items.
    """
    results: list[LocationSearchResult] = []

    # 1. Try Open-Meteo Geocoding API
    try:
        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            resp = await client.get(
                OPEN_METEO_GEO_BASE,
                params={"name": query, "count": 10, "language": "en", "format": "json"},
            )
            if resp.status_code == 200:
                raw_data = resp.json()
                raw_results = raw_data.get("results", [])
                for item in raw_results:
                    name = item.get("name", "")
                    admin1 = item.get("admin1", "")
                    country = item.get("country", "")
                    country_code = item.get("country_code", "")
                    lat = float(item.get("latitude", 0.0))
                    lon = float(item.get("longitude", 0.0))

                    parts = [p for p in [name, admin1, country] if p]
                    display = ", ".join(parts) if parts else name

                    results.append(
                        LocationSearchResult(
                            name=name,
                            display_name=display,
                            latitude=lat,
                            longitude=lon,
                            city=name,
                            state=admin1 or None,
                            country=country or None,
                            country_code=country_code.upper() if country_code else None,
                        )
                    )

                if results:
                    return results
    except Exception as exc:
        logger.warning("Open-Meteo geocoding search failed: %s — trying Nominatim fallback", exc)

    # 2. Fallback to Nominatim OSM search
    try:
        url = f"{NOMINATIM_BASE}/search"
        params = {
            "q": query,
            "format": "json",
            "addressdetails": 1,
            "limit": 8,
        }
        headers = {"User-Agent": USER_AGENT}

        async with httpx.AsyncClient(timeout=TIMEOUT) as client:
            resp = await client.get(url, params=params, headers=headers)

        if resp.status_code == 200:
            raw_list = resp.json()
            for item in raw_list:
                display_name = item.get("display_name", query)
                lat = float(item.get("lat", 0.0))
                lon = float(item.get("lon", 0.0))
                addr = item.get("address", {})

                name = (
                    addr.get("city")
                    or addr.get("town")
                    or addr.get("village")
                    or addr.get("suburb")
                    or display_name.split(",")[0]
                )
                state = addr.get("state") or addr.get("region")
                country = addr.get("country")
                country_code = addr.get("country_code")

                results.append(
                    LocationSearchResult(
                        name=name,
                        display_name=display_name,
                        latitude=lat,
                        longitude=lon,
                        city=name,
                        state=state,
                        country=country,
                        country_code=country_code.upper() if country_code else None,
                    )
                )

            return results
    except Exception as exc:
        logger.error("Nominatim search failed: %s", exc)

    return results
