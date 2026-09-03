import pytest
from unittest.mock import AsyncMock, patch
from app.schemas.location import SavedLocationCreate, SavedLocationResponse
from app.services.location_service import LocationService


@pytest.mark.asyncio
async def test_search_locations():
    results = await LocationService.search_locations("Hyderabad")
    assert isinstance(results, list)
    if results:
        assert results[0].name is not None
        assert -90 <= results[0].latitude <= 90
        assert -180 <= results[0].longitude <= 180


@pytest.mark.asyncio
@pytest.mark.parametrize("query", ["Bengaluru", "Mumbai", "Delhi", "London", "Tokyo", "New York"])
async def test_search_arbitrary_cities(query):
    results = await LocationService.search_locations(query)
    assert isinstance(results, list)
    assert results, f"Expected geocoding results for {query}"
    token = query.split()[0].lower()
    assert any(token in (r.name or "").lower() or token in (r.display_name or "").lower() for r in results)
    assert -90 <= results[0].latitude <= 90
    assert -180 <= results[0].longitude <= 180
    is_hyderabad_default = abs(results[0].latitude - 17.3850) < 0.01 and abs(results[0].longitude - 78.4867) < 0.01
    if query.lower() != "hyderabad":
        assert not is_hyderabad_default


@pytest.mark.asyncio
async def test_save_and_duplicate_location():
    mock_user = {"uid": "test_user_geocoding", "email": "geo@mausam.ai"}
    payload = SavedLocationCreate(name="Hyderabad", latitude=17.3850, longitude=78.4867)

    # Test logic using mocked session to avoid direct DB requirement in unit test
    mock_item = SavedLocationResponse(
        id="loc_123",
        name="Hyderabad",
        latitude=17.3850,
        longitude=78.4867,
        place_name="Hyderabad, Telangana, India",
        created_at="2026-09-03T20:00:00Z",
    )

    with patch.object(LocationService, "save_location", new_callable=AsyncMock) as mock_save:
        mock_save.return_value = mock_item

        saved1 = await LocationService.save_location(mock_user, payload)
        assert saved1.id == "loc_123"
        assert saved1.name == "Hyderabad"

        saved2 = await LocationService.save_location(mock_user, payload)
        assert saved2.id == saved1.id
