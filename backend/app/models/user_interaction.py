import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, func

from app.database.base import Base


class UserInteractionModel(Base):
    __tablename__ = "user_interactions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    card_id = Column(String, nullable=False, index=True)
    action_type = Column(String, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
