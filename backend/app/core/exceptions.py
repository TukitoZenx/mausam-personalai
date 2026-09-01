from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class AppException(Exception):
    def __init__(self, message: str, code: str = "BAD_REQUEST", status_code: int = status.HTTP_400_BAD_REQUEST):
        self.message = message
        self.code = code
        self.status_code = status_code
        super().__init__(message)

class UnauthorizedException(AppException):
    def __init__(self, message: str = "Invalid or missing authentication credentials"):
        super().__init__(message=message, code="UNAUTHORIZED", status_code=status.HTTP_401_UNAUTHORIZED)

class NotFoundException(AppException):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message=message, code="NOT_FOUND", status_code=status.HTTP_404_NOT_FOUND)

class ExternalServiceException(AppException):
    """Raised when an upstream external service (e.g. OpenWeatherMap) fails."""
    def __init__(self, message: str = "External service unavailable"):
        super().__init__(message=message, code="EXTERNAL_SERVICE_ERROR", status_code=status.HTTP_503_SERVICE_UNAVAILABLE)

async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
            }
        },
    )

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    code_map = {
        401: "UNAUTHORIZED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        400: "BAD_REQUEST",
    }
    code = code_map.get(exc.status_code, "ERROR")
    message = str(exc.detail) if hasattr(exc, "detail") else "HTTP Error"
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": code,
                "message": message,
            }
        },
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected error occurred on the server.",
            }
        },
    )
