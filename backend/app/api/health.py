from fastapi import APIRouter

from app.database.connection import check_db_health
from app.redis_client import check_redis_health

router = APIRouter(tags=["health"])

@router.get("/health")
async def health_check():
    db_ok = await check_db_health()
    redis_ok = await check_redis_health()
    
    status_str = "ok" if (db_ok and redis_ok) else "degraded"
    
    return {
        "status": status_str,
        "services": {
            "database": "connected" if db_ok else "disconnected",
            "redis": "connected" if redis_ok else "disconnected"
        }
    }
