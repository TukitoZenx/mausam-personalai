"""
Location service — geocoding search, reverse geocoding via Nominatim/Open-Meteo with Redis caching + PostGIS saved_locations CRUD.
"""

import json
import logging
from typing import Any

from sqlalchemy import delete, select, text

from app.core.exceptions import (
    ExternalServiceException,
    NotFoundException,
    UnauthorizedException,
)
from app.database.connection import AsyncSessionLocal
from app.models.saved_location import SavedLocationModel
from app.redis_client import redis_client
from app.schemas.location import (
    LocationInfo,
    LocationSearchResult,
    SavedLocationCreate,
    SavedLocationResponse,
)
from app.services.adapters import nominatim_adapter as nominatim

logger = logging.getLogger(__name__)

_TTL_REVERSE_GEO = 86400  # 24 hours in seconds


def _key_reverse(lat: float, lon: float) -> str:
    return f"location:reverse:{lat:.4f}:{lon:.4f}"


class LocationService:

    @staticmethod
    async def search_locations(query: str) -> list[LocationSearchResult]:
        """
        Forward geocode search query to list of candidate locations.
        """
        if not query or len(query.strip()) == 0:
            return []
        return await nominatim.search_locations(query.strip())

    @staticmethod
    async def get_current_location(lat: float, lon: float) -> LocationInfo:
        """
        Reverse geocode lat/lon to place name.
        Uses Redis cache (24h TTL) + stale fallback on upstream failure.
        """
        cache_key = _key_reverse(lat, lon)

        # 1. Check Redis cache
        cached_raw = await redis_client.get(cache_key)
        if cached_raw:
            data = json.loads(cached_raw)
            data["cached"] = True
            data["stale"] = False
            logger.info("Cache HIT: %s", cache_key)
            return LocationInfo(**data)

        # 2. Fetch from Nominatim
        logger.info("Cache MISS: %s — calling Nominatim reverse geocode", cache_key)
        try:
            result = await nominatim.reverse_geocode(lat, lon)
            result.cached = False
            result.stale = False

            payload = result.model_dump()
            payload.pop("cached", None)
            payload.pop("stale", None)
            serialized = json.dumps(payload)

            await redis_client.setex(cache_key, _TTL_REVERSE_GEO, serialized)
            await redis_client.set(f"stale:{cache_key}", serialized)

            return result

        except ExternalServiceException as exc:
            stale_raw = await redis_client.get(f"stale:{cache_key}")
            if stale_raw:
                data = json.loads(stale_raw)
                data["cached"] = False
                data["stale"] = True
                logger.warning("Returning STALE cache for %s due to upstream failure: %s", cache_key, exc)
                return LocationInfo(**data)
            # Fallback if external API fails completely
            return LocationInfo(
                latitude=lat,
                longitude=lon,
                place_name=f"{lat:.2f}, {lon:.2f}",
                cached=False,
                stale=True,
            )

    @staticmethod
    async def save_location(user: dict[str, Any], payload: SavedLocationCreate) -> SavedLocationResponse:
        """
        Create or resolve saved location for current user in database.
        Handles duplicates gracefully without throwing errors.
        """
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        place_name = payload.name.strip()
        email = user.get("email") or f"{user_id}@mausam.ai"
        # Generic stub emails are shared across test tokens — uniquify to avoid UNIQUE(email) collisions.
        if email in {"user@mausam.ai", "guest@mausam.ai"}:
            email = f"{user_id}@mausam.ai"

        async with AsyncSessionLocal() as session:
            # 1. Ensure user row exists to satisfy FK constraint.
            # users table has (id, email, ...) — there is no firebase_uid column.
            try:
                await session.execute(
                    text(
                        "INSERT INTO users (id, email, persona_type, notifications_enabled, location_access) "
                        "VALUES (:id, :email, 'Fitness', true, true) "
                        "ON CONFLICT (id) DO NOTHING"
                    ),
                    {"id": user_id, "email": email},
                )
                await session.commit()
            except Exception as exc:
                logger.warning("Ensure user row failed (continuing with save): %s", exc)
                await session.rollback()

            # 2. Check for duplicate location (same place, not merely the same city name worldwide)
            existing_stmt = select(SavedLocationModel).where(
                SavedLocationModel.user_id == user_id,
            )
            res = await session.execute(existing_stmt)
            existing_records = res.scalars().all()

            for item in existing_records:
                same_name = item.name.lower().strip() == place_name.lower()
                close_coords = (
                    abs(item.latitude - payload.latitude) < 0.05
                    and abs(item.longitude - payload.longitude) < 0.05
                )
                # Treat as duplicate only when coordinates are near, or the same name is also nearby.
                nearby_same_name = same_name and (
                    abs(item.latitude - payload.latitude) < 1.0
                    and abs(item.longitude - payload.longitude) < 1.0
                )
                if close_coords or nearby_same_name:
                    logger.info("Found existing saved location for user %s: %s (%s)", user_id, item.name, item.id)
                    return SavedLocationResponse(
                        id=item.id,
                        name=item.name,
                        latitude=item.latitude,
                        longitude=item.longitude,
                        place_name=item.name,
                        created_at=item.created_at.isoformat() if item.created_at else "",
                    )

            # 3. Create new saved location row
            db_item = SavedLocationModel(
                user_id=user_id,
                name=place_name,
                latitude=payload.latitude,
                longitude=payload.longitude,
            )
            session.add(db_item)
            await session.commit()
            await session.refresh(db_item)

            # 4. Try updating PostGIS geometry if extension is available
            try:
                await session.execute(
                    text(
                        "UPDATE saved_locations "
                        "SET geo_point = ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography "
                        "WHERE id = :id"
                    ),
                    {"lat": payload.latitude, "lon": payload.longitude, "id": db_item.id},
                )
                await session.commit()
            except Exception as exc:
                logger.warning("PostGIS geo_point update skipped or failed: %s", exc)

            return SavedLocationResponse(
                id=db_item.id,
                name=db_item.name,
                latitude=db_item.latitude,
                longitude=db_item.longitude,
                place_name=place_name,
                created_at=db_item.created_at.isoformat() if db_item.created_at else "",
            )

    @staticmethod
    async def get_saved_locations(user: dict[str, Any]) -> list[SavedLocationResponse]:
        """
        List all saved locations for current user.
        """
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        async with AsyncSessionLocal() as session:
            stmt = select(SavedLocationModel).where(SavedLocationModel.user_id == user_id).order_by(SavedLocationModel.created_at.desc())
            res = await session.execute(stmt)
            records = res.scalars().all()

            results: list[SavedLocationResponse] = []
            for item in records:
                results.append(
                    SavedLocationResponse(
                        id=item.id,
                        name=item.name,
                        latitude=item.latitude,
                        longitude=item.longitude,
                        place_name=item.name,
                        created_at=item.created_at.isoformat() if item.created_at else "",
                    )
                )
            return results

    @staticmethod
    async def delete_saved_location(user: dict[str, Any], location_id: str) -> None:
        """
        Delete a saved location, scoped to owning user only.
        """
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        async with AsyncSessionLocal() as session:
            stmt = select(SavedLocationModel).where(SavedLocationModel.id == location_id)
            res = await session.execute(stmt)
            record = res.scalar_one_or_none()

            if not record:
                raise NotFoundException("Saved location not found")

            if record.user_id != user_id:
                raise UnauthorizedException("Forbidden: You do not own this saved location")

            del_stmt = delete(SavedLocationModel).where(SavedLocationModel.id == location_id)
            await session.execute(del_stmt)
            await session.commit()
