
from pydantic import BaseModel


class AlertResponse(BaseModel):
    id: str
    headline: str
    severity: str
    description: str
    issued_at: str
    status: str = "stub"

class AlertSubscription(BaseModel):
    enabled: bool
    push_token: str | None = None
    alert_types: list[str] | None = None
