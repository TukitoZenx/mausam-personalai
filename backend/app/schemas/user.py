from typing import Optional
from pydantic import BaseModel

class UserProfile(BaseModel):
    email: str
    persona_type: str
    persona: str
    notifications_enabled: bool = True
    location_access: bool = True

class UserProfileUpdate(BaseModel):
    email: Optional[str] = None
    persona: Optional[str] = None
    persona_type: Optional[str] = None
    notifications_enabled: Optional[bool] = None
    location_access: Optional[bool] = None
    interests: Optional[str] = None
