import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Index, String, func

from app.database.base import Base


class ReminderModel(Base):
    __tablename__ = "reminders"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    time_of_day = Column(String, nullable=False)
    frequency = Column(String, nullable=False, default="daily")  # "once" or "daily"
    location_id = Column(String, ForeignKey("saved_locations.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_sent_at = Column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        Index("ix_reminders_user_time", "user_id", "time_of_day"),
    )
