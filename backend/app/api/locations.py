from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.location import SavedLocation, SavedLocationCreate
from app.services.location_service import LocationService

router = APIRouter(prefix="/locations", tags=["locations"])

@router.get("/current", response_model=SavedLocation)
async def get_current_location(current_user: dict[str, Any] = Depends(get_current_user)):
    return await LocationService.get_current_location(current_user)

@router.post("/saved", response_model=SavedLocation)
async def save_location(
    body: SavedLocationCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await LocationService.save_location(current_user, body)
