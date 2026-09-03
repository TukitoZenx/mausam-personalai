from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.alert import AlertResponse, AlertSubscription
from app.services.alert_service import AlertService

router = APIRouter(prefix="/alerts", tags=["alerts"])

@router.get("", response_model=list[AlertResponse])
async def get_alerts(
    lat: float | None = None,
    lon: float | None = None,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await AlertService.get_alerts(current_user, lat=lat, lon=lon)

@router.post("/subscribe")
async def subscribe_alerts(
    body: AlertSubscription,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await AlertService.subscribe_alerts(current_user, body)
