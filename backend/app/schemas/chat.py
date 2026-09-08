from typing import Any
from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    text: str = Field(..., min_length=1, description="User prompt or weather query")
    latitude: float | None = Field(None, description="Optional latitude")
    longitude: float | None = Field(None, description="Optional longitude")
    lat: float | None = Field(None, description="Alternative latitude field")
    lon: float | None = Field(None, description="Alternative longitude field")

    @property
    def resolved_lat(self) -> float | None:
        return self.latitude if self.latitude is not None else self.lat

    @property
    def resolved_lon(self) -> float | None:
        return self.longitude if self.longitude is not None else self.lon


class ChatMessageResponse(BaseModel):
    reply: str
    intent: str = "weather"
    weather_data: dict[str, Any] | None = None
    suggested_actions: list[str] = Field(default_factory=list)
    reminder_created: bool = False
    reminder_details: dict[str, Any] | None = None


class ReminderCreate(BaseModel):
    time_of_day: str = Field(..., description="Time of day in HH:MM format (24h or 12h e.g. '07:00' or '7:00 AM')")
    frequency: str = Field("daily", description="'daily' or 'once'")
    location_id: str | None = Field(None, description="Optional saved location ID")


class ReminderResponse(BaseModel):
    id: str
    user_id: str
    time_of_day: str
    frequency: str
    location_id: str | None = None
    created_at: str | None = None
    last_sent_at: str | None = None
    delivery_status: str = "not yet wired to FCM"


class ReminderCheckResult(BaseModel):
    checked_at: str
    due_count: int
    dispatched: list[dict[str, Any]]
    delivery_status: str = "not yet wired to FCM"
