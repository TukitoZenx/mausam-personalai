from typing import Any

from app.schemas.location import SavedLocation, SavedLocationCreate


class LocationService:
    @staticmethod
    async def get_current_location(user: dict[str, Any]) -> SavedLocation:
        return SavedLocation(
            id="loc_curr_01",
            name="Current Location (San Francisco)",
            latitude=37.7749,
            longitude=-122.4194,
            is_favorite=True,
            status="stub",
        )

    @staticmethod
    async def save_location(user: dict[str, Any], payload: SavedLocationCreate) -> SavedLocation:
        return SavedLocation(
            id="loc_saved_02",
            name=payload.name,
            latitude=payload.latitude,
            longitude=payload.longitude,
            is_favorite=payload.is_favorite if payload.is_favorite is not None else True,
            status="stub",
        )
