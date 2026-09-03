from typing import Any

from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user
from app.schemas.location import (
    LocationInfo,
    LocationSearchResult,
    SavedLocationCreate,
    SavedLocationResponse,
)
from app.services.location_service import LocationService

router = APIRouter(prefix="/locations", tags=["locations"])


@router.get("/search", response_model=list[LocationSearchResult])
async def search_locations(
    q: str = Query(..., description="Location search query", min_length=1),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    Search location candidates by name or query string.
    """
    return await LocationService.search_locations(q)


@router.get("/current", response_model=LocationInfo)
async def get_current_location(
    lat: float = Query(..., description="Latitude", ge=-90, le=90),
    lon: float = Query(..., description="Longitude", ge=-180, le=180),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await LocationService.get_current_location(lat, lon)


@router.get("/saved", response_model=list[SavedLocationResponse])
async def get_saved_locations(
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await LocationService.get_saved_locations(current_user)


@router.post("/saved", response_model=SavedLocationResponse, status_code=status.HTTP_201_CREATED)
async def save_location(
    body: SavedLocationCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await LocationService.save_location(current_user, body)


@router.delete("/saved/{location_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_saved_location(
    location_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    await LocationService.delete_saved_location(current_user, location_id)
