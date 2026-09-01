
from pydantic import BaseModel


class UserProfile(BaseModel):
    email: str
    persona_type: str
    persona: str
    notifications_enabled: bool = True
    location_access: bool = True

class UserProfileUpdate(BaseModel):
    email: str | None = None
    persona: str | None = None
    persona_type: str | None = None
    notifications_enabled: bool | None = None
    location_access: bool | None = None
    interests: str | None = None
