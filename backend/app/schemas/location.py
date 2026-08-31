from typing import Optional
from pydantic import BaseModel

class SavedLocationCreate(BaseModel):
    name: str
    latitude: float
    longitude: float
    is_favorite: Optional[bool] = True

class SavedLocation(BaseModel):
    id: str
    name: str
    latitude: float
    longitude: float
    is_favorite: bool
    status: str = "stub"
