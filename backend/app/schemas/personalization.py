
from typing import Any
from pydantic import BaseModel


class HomeCard(BaseModel):
    id: str | None = None
    title: str | None = None
    subtitle: str | None = None
    category: str | None = None
    action_label: str | None = None
    card_type: str | None = None
    score: float | None = 0.0
    rank: int | None = 1
    reason_codes: list[str] | None = None
    reason: str | None = None
    human_readable_reason: str | None = None
    data: dict[str, Any] | None = None

class PersonalizedHomeResponse(BaseModel):
    persona: str | None = "Fitness"
    greeting: str | None = None
    summary_insight: str | None = None
    generated_at: str | None = None
    location: str | dict[str, Any] | None = None
    degraded_context: bool | None = False
    cards: list[HomeCard] = []
    status: str = "stub"

class InteractionEvent(BaseModel):
    card_id: str | None = None
    action_type: str | None = None
    card_type: str | None = None
    action: str | None = None
    timestamp: str | None = None

