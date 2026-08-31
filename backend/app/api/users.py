from typing import Dict, Any
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.schemas.user import UserProfile, UserProfileUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me", response_model=UserProfile)
async def get_my_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    return await UserService.get_user_profile(current_user)

@router.post("/me", response_model=UserProfile)
async def update_my_profile(
    body: UserProfileUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    return await UserService.update_user_profile(current_user, body)
