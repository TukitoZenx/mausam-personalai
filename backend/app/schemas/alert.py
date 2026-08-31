from typing import Optional
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
    push_token: Optional[str] = None
    alert_types: Optional[list[str]] = None
