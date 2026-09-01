import redis.asyncio as redis

from app.config import settings

redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

async def check_redis_health() -> bool:
    try:
        res = await redis_client.ping()
        return res is True
    except Exception as e:
        print(f"Redis health check failed: {e}")
        return False
