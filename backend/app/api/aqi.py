from typing import Any

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.schemas.aqi import AQIResponse
from app.services.aqi_service import AQIService

router = APIRouter(prefix="/aqi", tags=["aqi"])


@router.get("/current", response_model=AQIResponse)
async def get_current_aqi(
    lat: float = Query(..., description="Latitude", ge=-90, le=90),
    lon: float = Query(..., description="Longitude", ge=-180, le=180),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await AQIService.get_current_aqi(lat, lon)
