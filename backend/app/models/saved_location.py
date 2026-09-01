import uuid

from geoalchemy2 import Geography
from sqlalchemy import Column, DateTime, Float, ForeignKey, String, func

from app.database.base import Base


class SavedLocationModel(Base):
    __tablename__ = "saved_locations"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    geo_point = Column(Geography(geometry_type="POINT", srid=4326), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
