from typing import Optional
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/users", tags=["users"])

# Simple in-memory store for demo/local testing
_user_db: dict[str, dict] = {}

class UserProfileRequest(BaseModel):
    email: Optional[str] = None
    persona: Optional[str] = None
    persona_type: Optional[str] = None
    notifications_enabled: Optional[bool] = True
    location_access: Optional[bool] = True
    interests: Optional[str] = None

@router.post("/me")
async def update_current_user(
    body: UserProfileRequest,
    authorization: Optional[str] = Header(None)
):
    token = "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1]

    existing = _user_db.get(token, {})

    persona_val = body.persona_type or body.persona or existing.get("persona_type") or "Fitness"

    user_data = {
        "email": body.email or existing.get("email") or "user@mausam.ai",
        "persona_type": persona_val,
        "persona": persona_val,
        "notifications_enabled": body.notifications_enabled if body.notifications_enabled is not None else existing.get("notifications_enabled", True),
        "location_access": body.location_access if body.location_access is not None else existing.get("location_access", True),
    }

    _user_db[token] = user_data
    _user_db["latest"] = user_data

    return user_data

@router.get("/me")
async def get_current_user(
    authorization: Optional[str] = Header(None)
):
    token = "default_user"
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1]

    if token in _user_db:
        return _user_db[token]
    elif "latest" in _user_db:
        return _user_db["latest"]
    
    return {
        "email": "user@mausam.ai",
        "persona_type": "Fitness",
        "persona": "Fitness",
        "notifications_enabled": True,
        "location_access": True
    }
