import uuid
from typing import Any

from sqlalchemy import text

from app.database.connection import AsyncSessionLocal
from app.schemas.user import UserProfileUpdate


class UserService:
    @staticmethod
    async def get_user_profile(user: dict[str, Any]) -> dict[str, Any]:
        uid = user.get("uid", "default_user")
        email = user.get("email") or "user@mausam.ai"

        try:
            async with AsyncSessionLocal() as session:
                res = await session.execute(
                    text("SELECT id, email, persona_type, notifications_enabled, location_access FROM users WHERE id = :uid OR email = :email LIMIT 1"),
                    {"uid": uid, "email": email},
                )
                row = res.fetchone()
                if row:
                    r = row._mapping
                    persona = r.get("persona_type") or "Fitness"
                    return {
                        "email": r.get("email") or email,
                        "persona_type": persona,
                        "persona": persona,
                        "notifications_enabled": bool(r.get("notifications_enabled")),
                        "location_access": bool(r.get("location_access")),
                    }
        except Exception:
            pass

        return {
            "email": email,
            "persona_type": "Fitness",
            "persona": "Fitness",
            "notifications_enabled": True,
            "location_access": True,
        }

    @staticmethod
    async def update_user_profile(user: dict[str, Any], payload: UserProfileUpdate) -> dict[str, Any]:
        uid = user.get("uid") or "default_user"
        email = payload.email or user.get("email") or "user@mausam.ai"

        # Determine target values
        persona_val = payload.persona_type or payload.persona or "Fitness"
        notif_enabled = payload.notifications_enabled if payload.notifications_enabled is not None else True
        loc_access = payload.location_access if payload.location_access is not None else True

        async with AsyncSessionLocal() as session:
            await session.execute(
                text(
                    """
                    INSERT INTO users (
                        id, email, persona_type, notifications_enabled, location_access, updated_at
                    ) VALUES (
                        :id, :email, :persona_type, :notifications_enabled, :location_access, NOW()
                    )
                    ON CONFLICT (id) DO UPDATE SET
                        email = EXCLUDED.email,
                        persona_type = EXCLUDED.persona_type,
                        notifications_enabled = EXCLUDED.notifications_enabled,
                        location_access = EXCLUDED.location_access,
                        updated_at = NOW()
                    """
                ),
                {
                    "id": uid,
                    "email": email,
                    "persona_type": persona_val,
                    "notifications_enabled": notif_enabled,
                    "location_access": loc_access,
                },
            )
            await session.commit()

        return {
            "email": email,
            "persona_type": persona_val,
            "persona": persona_val,
            "notifications_enabled": notif_enabled,
            "location_access": loc_access,
        }
