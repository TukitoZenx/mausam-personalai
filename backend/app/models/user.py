from sqlalchemy import Boolean, Column, DateTime, String, func

from app.database.base import Base


class UserModel(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    persona_type = Column(String, default="Fitness")
    notifications_enabled = Column(Boolean, default=True)
    location_access = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
