from fastapi import APIRouter
from .places import router as places_router
from .reviews import router as reviews_router

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(places_router, prefix="/places", tags=["places"])
api_router.include_router(reviews_router, prefix="/reviews", tags=["reviews"])