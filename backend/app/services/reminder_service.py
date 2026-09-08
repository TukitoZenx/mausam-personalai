from datetime import datetime, timezone
import logging
import re
from typing import Any
import uuid

from sqlalchemy import delete, select, text

from app.core.exceptions import NotFoundException, UnauthorizedException
from app.database.connection import AsyncSessionLocal
from app.models.reminder import ReminderModel
from app.schemas.chat import ReminderCheckResult, ReminderCreate, ReminderResponse

logger = logging.getLogger(__name__)


def normalize_time_str(raw: str) -> str:
    """
    Standardize various time inputs into HH:MM (24-hour) format.
    Examples:
      '7am' -> '07:00'
      '7:00 am' -> '07:00'
      '7 PM' -> '19:00'
      '19:30' -> '19:30'
      '07:00' -> '07:00'
    """
    s = raw.strip().lower()
    # Match patterns like 7am, 7:30pm, 7:00 am, 14:20
    m = re.match(r"^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$", s)
    if not m:
        # If no match, clean up and return original or fallback
        return s

    hour = int(m.group(1))
    minute = int(m.group(2)) if m.group(2) else 0
    meridiem = m.group(3)

    if meridiem == "pm" and hour < 12:
        hour += 12
    elif meridiem == "am" and hour == 12:
        hour = 0

    return f"{hour:02d}:{minute:02d}"


class ReminderService:

    @staticmethod
    async def create_reminder(user: dict[str, Any], payload: ReminderCreate) -> ReminderResponse:
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        email = user.get("email") or f"{user_id}@mausam.ai"
        if email in {"user@mausam.ai", "guest@mausam.ai"}:
            email = f"{user_id}@mausam.ai"

        normalized_time = normalize_time_str(payload.time_of_day)
        frequency = payload.frequency.lower().strip()
        if frequency not in {"daily", "once"}:
            frequency = "daily"

        async with AsyncSessionLocal() as session:
            # 1. Ensure user exists to satisfy foreign key constraint
            try:
                await session.execute(
                    text(
                        "INSERT INTO users (id, email, persona_type, notifications_enabled, location_access) "
                        "VALUES (:id, :email, 'Fitness', true, true) "
                        "ON CONFLICT (id) DO NOTHING"
                    ),
                    {"id": user_id, "email": email},
                )
                await session.commit()
            except Exception as exc:
                logger.warning("Ensure user row in create_reminder: %s", exc)
                await session.rollback()

            # 2. Check if identical reminder already exists for user
            stmt = select(ReminderModel).where(
                ReminderModel.user_id == user_id,
                ReminderModel.time_of_day == normalized_time,
                ReminderModel.frequency == frequency,
            )
            res = await session.execute(stmt)
            existing = res.scalars().first()
            if existing:
                return ReminderResponse(
                    id=existing.id,
                    user_id=existing.user_id,
                    time_of_day=existing.time_of_day,
                    frequency=existing.frequency,
                    location_id=existing.location_id,
                    created_at=existing.created_at.isoformat() if existing.created_at else None,
                    last_sent_at=existing.last_sent_at.isoformat() if existing.last_sent_at else None,
                    delivery_status="not yet wired to FCM",
                )

            # 3. Create new reminder
            reminder = ReminderModel(
                id=str(uuid.uuid4()),
                user_id=user_id,
                time_of_day=normalized_time,
                frequency=frequency,
                location_id=payload.location_id,
            )
            session.add(reminder)
            await session.commit()
            await session.refresh(reminder)

            return ReminderResponse(
                id=reminder.id,
                user_id=reminder.user_id,
                time_of_day=reminder.time_of_day,
                frequency=reminder.frequency,
                location_id=reminder.location_id,
                created_at=reminder.created_at.isoformat() if reminder.created_at else None,
                last_sent_at=None,
                delivery_status="not yet wired to FCM",
            )

    @staticmethod
    async def get_reminders(user: dict[str, Any]) -> list[ReminderResponse]:
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        async with AsyncSessionLocal() as session:
            stmt = (
                select(ReminderModel)
                .where(ReminderModel.user_id == user_id)
                .order_by(ReminderModel.time_of_day.asc())
            )
            res = await session.execute(stmt)
            records = res.scalars().all()

            return [
                ReminderResponse(
                    id=item.id,
                    user_id=item.user_id,
                    time_of_day=item.time_of_day,
                    frequency=item.frequency,
                    location_id=item.location_id,
                    created_at=item.created_at.isoformat() if item.created_at else None,
                    last_sent_at=item.last_sent_at.isoformat() if item.last_sent_at else None,
                    delivery_status="not yet wired to FCM",
                )
                for item in records
            ]

    @staticmethod
    async def delete_reminder(user: dict[str, Any], reminder_id: str) -> None:
        user_id = user.get("uid")
        if not user_id:
            raise UnauthorizedException("User ID missing from authentication context.")

        async with AsyncSessionLocal() as session:
            stmt = select(ReminderModel).where(ReminderModel.id == reminder_id)
            res = await session.execute(stmt)
            record = res.scalar_one_or_none()

            if not record:
                raise NotFoundException(f"Reminder with ID '{reminder_id}' not found.")

            if record.user_id != user_id:
                raise UnauthorizedException("Forbidden: You do not own this reminder.")

            del_stmt = delete(ReminderModel).where(ReminderModel.id == reminder_id)
            await session.execute(del_stmt)
            await session.commit()

    @staticmethod
    async def check_due_reminders(target_time: str | None = None) -> ReminderCheckResult:
        """
        Scheduled job method: checks for reminders due at `target_time` (or current local/UTC minute).
        Logs what WOULD have been sent (clearly labeled as 'not yet wired to FCM').
        """
        now_dt = datetime.now(timezone.utc)
        eval_time = target_time if target_time else now_dt.strftime("%H:%M")
        normalized_eval_time = normalize_time_str(eval_time)

        logger.info("[REMINDER SCHEDULER] Checking reminders due at %s", normalized_eval_time)

        dispatched: list[dict[str, Any]] = []

        async with AsyncSessionLocal() as session:
            stmt = select(ReminderModel).where(ReminderModel.time_of_day == normalized_eval_time)
            res = await session.execute(stmt)
            due_reminders = res.scalars().all()

            for r in due_reminders:
                summary_message = (
                    f"Good day! Here is your scheduled {r.frequency} weather summary for {r.time_of_day}: "
                    "Current forecast radar is active and personalized to your routine."
                )

                log_entry = {
                    "reminder_id": r.id,
                    "user_id": r.user_id,
                    "time_of_day": r.time_of_day,
                    "frequency": r.frequency,
                    "simulated_push_title": "🌤️ Mausam Weather Briefing",
                    "simulated_push_body": summary_message,
                    "delivery_status": "not yet wired to FCM (push delivery simulated and logged)",
                }
                dispatched.append(log_entry)

                logger.info(
                    "[REMINDER DISPATCH SIMULATION - NOT YET WIRED TO FCM] "
                    "User: %s | Time: %s (%s) | Title: %s | Body: %s",
                    r.user_id,
                    r.time_of_day,
                    r.frequency,
                    log_entry["simulated_push_title"],
                    log_entry["simulated_push_body"],
                )

                # Update last_sent_at
                r.last_sent_at = now_dt
                if r.frequency == "once":
                    # Remove one-time reminders after trigger
                    await session.delete(r)

            await session.commit()

        return ReminderCheckResult(
            checked_at=now_dt.isoformat(),
            due_count=len(dispatched),
            dispatched=dispatched,
            delivery_status="not yet wired to FCM",
        )
