
from pydantic import BaseModel


class HomeCard(BaseModel):
    id: str
    title: str
    subtitle: str
    category: str
    action_label: str

class PersonalizedHomeResponse(BaseModel):
    persona: str
    greeting: str
    summary_insight: str
    cards: list[HomeCard]
    status: str = "stub"

class InteractionEvent(BaseModel):
    card_id: str
    action_type: str
    timestamp: str | None = None
