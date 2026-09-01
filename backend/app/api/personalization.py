from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.personalization import InteractionEvent, PersonalizedHomeResponse
from app.services.personalization_service import PersonalizationService

router = APIRouter(prefix="/personalization", tags=["personalization"])

@router.get("/home", response_model=PersonalizedHomeResponse)
async def get_personalized_home(
    lat: float | None = None,
    lon: float | None = None,
    saved_location_id: str | None = None,
    hour: int | None = None,
    tz: str | None = None,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await PersonalizationService.get_home_feed(
        current_user,
        lat=lat,
        lon=lon,
        saved_location_id=saved_location_id,
        hour=hour,
        tz=tz,
    )

@router.post("/interactions")
async def record_interaction(
    body: InteractionEvent,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await PersonalizationService.record_interaction(current_user, body)

