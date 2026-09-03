from pydantic import BaseModel, Field


class LocationInfo(BaseModel):
    latitude: float
    longitude: float
    place_name: str
    city: str | None = None
    state_region: str | None = None
    cached: bool = False
    stale: bool = False


class LocationSearchResult(BaseModel):
    name: str
    display_name: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    city: str | None = None
    state: str | None = None
    country: str | None = None
    country_code: str | None = None


class SavedLocationCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class SavedLocationResponse(BaseModel):
    id: str
    name: str
    latitude: float
    longitude: float
    place_name: str | None = None
    created_at: str
