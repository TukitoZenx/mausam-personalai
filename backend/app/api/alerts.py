from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.alert import AlertResponse, AlertSubscription
from app.services.alert_service import AlertService

router = APIRouter(prefix="/alerts", tags=["alerts"])

@router.get("", response_model=list[AlertResponse])
async def get_alerts(current_user: dict[str, Any] = Depends(get_current_user)):
    return await AlertService.get_alerts(current_user)

@router.post("/subscribe")
async def subscribe_alerts(
    body: AlertSubscription,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    return await AlertService.subscribe_alerts(current_user, body)
