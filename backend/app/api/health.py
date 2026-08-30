from fastapi import APIRouter, Response, status
from app.db import check_db_health
from app.redis_client import check_redis_health

router = APIRouter()

@router.get("/health")
async def health_check(response: Response):
    db_ok = await check_db_health()
    redis_ok = await check_redis_health()

    is_healthy = db_ok and redis_ok
    if not is_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return {
        "status": "healthy" if is_healthy else "unhealthy",
        "database": "connected" if db_ok else "disconnected",
        "redis": "connected" if redis_ok else "disconnected"
    }
