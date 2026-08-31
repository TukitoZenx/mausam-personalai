from typing import Dict, Any
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas.aqi import AQIResponse
from app.services.aqi_service import AQIService

router = APIRouter(prefix="/aqi", tags=["aqi"])

@router.get("/current", response_model=AQIResponse)
async def get_current_aqi(current_user: Dict[str, Any] = Depends(get_current_user)):
    return await AQIService.get_current_aqi(current_user)
