from typing import Dict, Any
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas.personalization import PersonalizedHomeResponse, InteractionEvent
from app.services.personalization_service import PersonalizationService

router = APIRouter(prefix="/personalization", tags=["personalization"])

@router.get("/home", response_model=PersonalizedHomeResponse)
async def get_personalized_home(current_user: Dict[str, Any] = Depends(get_current_user)):
    return await PersonalizationService.get_home_feed(current_user)

@router.post("/interactions")
async def record_interaction(
    body: InteractionEvent,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    return await PersonalizationService.record_interaction(current_user, body)
