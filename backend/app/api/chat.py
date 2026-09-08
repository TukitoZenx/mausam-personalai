from typing import Any

from fastapi import APIRouter, Depends, Query, status

from app.api.deps import get_current_user
from app.schemas.chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ReminderCheckResult,
    ReminderCreate,
    ReminderResponse,
)
from app.services.chat_service import ChatService
from app.services.reminder_service import ReminderService

router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/message", response_model=ChatMessageResponse)
async def send_chat_message(
    body: ChatMessageRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    Takes user text + lat/lon, returns a natural-language reply generated
    from REAL live data already available (weather, forecast, aqi).
    """
    return await ChatService.process_message(current_user, body)


@router.post("/reminders", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_reminder(
    body: ReminderCreate,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    Create a new weather summary reminder schedule for the current user.
    """
    return await ReminderService.create_reminder(current_user, body)


@router.get("/reminders", response_model=list[ReminderResponse])
async def list_reminders(
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    List all active reminders for the current user.
    """
    return await ReminderService.get_reminders(current_user)


@router.delete("/reminders/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    reminder_id: str,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    Delete a reminder schedule belonging to the current user.
    """
    await ReminderService.delete_reminder(current_user, reminder_id)


@router.post("/reminders/check", response_model=ReminderCheckResult)
async def trigger_reminder_check(
    target_time: str | None = Query(None, description="Optional target time HH:MM to simulate or check"),
    current_user: dict[str, Any] = Depends(get_current_user),
):
    """
    Check due reminders and simulate/dispatch push notifications (labeled as 'not yet wired to FCM').
    """
    return await ReminderService.check_due_reminders(target_time=target_time)
