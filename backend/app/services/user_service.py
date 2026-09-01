from typing import Any

from app.schemas.user import UserProfileUpdate

_user_db: dict[str, dict[str, Any]] = {}

class UserService:
    @staticmethod
    async def get_user_profile(user: dict[str, Any]) -> dict[str, Any]:
        uid = user.get("uid", "default_user")
        if uid in _user_db:
            return _user_db[uid]
        elif "latest" in _user_db:
            return _user_db["latest"]
        
        return {
            "email": user.get("email") or "user@mausam.ai",
            "persona_type": "Fitness",
            "persona": "Fitness",
            "notifications_enabled": True,
            "location_access": True,
        }

    @staticmethod
    async def update_user_profile(user: dict[str, Any], payload: UserProfileUpdate) -> dict[str, Any]:
        uid = user.get("uid", "default_user")
        existing = _user_db.get(uid, {})
        persona_val = payload.persona_type or payload.persona or existing.get("persona_type") or "Fitness"

        updated = {
            "email": payload.email or existing.get("email") or user.get("email") or "user@mausam.ai",
            "persona_type": persona_val,
            "persona": persona_val,
            "notifications_enabled": payload.notifications_enabled if payload.notifications_enabled is not None else existing.get("notifications_enabled", True),
            "location_access": payload.location_access if payload.location_access is not None else existing.get("location_access", True),
        }

        _user_db[uid] = updated
        _user_db["latest"] = updated
        return updated
