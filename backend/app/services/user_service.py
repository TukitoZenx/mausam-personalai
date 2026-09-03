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

        async with AsyncSessionLocal() as session:
            res = await session.execute(
                text("SELECT firebase_uid, email, persona, notification_opt_in, location_permission_status, location_permission_granted FROM users WHERE firebase_uid = :uid LIMIT 1"),
                {"uid": uid},
            )
            row = res.fetchone()
            if row:
                r = row._mapping
                return {
                    "email": r.get("email") or email,
                    "persona_type": r.get("persona") or "Fitness",
                    "persona": r.get("persona") or "Fitness",
                    "notifications_enabled": bool(r.get("notification_opt_in")),
                    "location_access": bool(r.get("location_permission_granted")),
                }

        return {
            "email": email,
            "persona_type": "Fitness",
            "persona": "Fitness",
            "notifications_enabled": True,
            "location_access": True,
        }

    @staticmethod
    async def update_user_profile(user: dict[str, Any], payload: UserProfileUpdate) -> dict[str, Any]:
        uid = user.get("uid", "default_user")
        email = payload.email or user.get("email") or "user@mausam.ai"

        # Determine target values
        persona_val = payload.persona_type or payload.persona or "Fitness"
        notif_enabled = payload.notifications_enabled if payload.notifications_enabled is not None else True
        loc_access = payload.location_access if payload.location_access is not None else True
        loc_status = "granted" if loc_access else "denied"
        new_id = str(uuid.uuid4())

        async with AsyncSessionLocal() as session:
            await session.execute(
                text(
                    """
                    INSERT INTO users (
                        id, firebase_uid, email, persona, notification_opt_in, 
                        location_permission_status, location_permission_granted
                    ) VALUES (
                        :id, :firebase_uid, :email, :persona, :notification_opt_in, 
                        :location_permission_status, :location_permission_granted
                    )
                    ON CONFLICT (firebase_uid) DO UPDATE SET
                        email = EXCLUDED.email,
                        persona = EXCLUDED.persona,
                        notification_opt_in = EXCLUDED.notification_opt_in,
                        location_permission_status = EXCLUDED.location_permission_status,
                        location_permission_granted = EXCLUDED.location_permission_granted
                    """
                ),
                {
                    "id": new_id,
                    "firebase_uid": uid,
                    "email": email,
                    "persona": persona_val,
                    "notification_opt_in": notif_enabled,
                    "location_permission_status": loc_status,
                    "location_permission_granted": loc_access,
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
