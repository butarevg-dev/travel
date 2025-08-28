from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from app.models.place import PlaceCategory, PlaceSubcategory, PriceTier


class PlaceBase(BaseModel):
    title_ru: str = Field(..., min_length=1, max_length=255)
    title_en: str = Field(..., min_length=1, max_length=255)
    description_ru: str = Field(..., min_length=1)
    description_en: str = Field(..., min_length=1)
    category: PlaceCategory
    subcategory: PlaceSubcategory
    tags: List[str] = Field(default_factory=list)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address_ru: Optional[str] = Field(None, max_length=500)
    address_en: Optional[str] = Field(None, max_length=500)
    price_tier: PriceTier = PriceTier.FREE
    is_commercial: bool = False
    website: Optional[str] = Field(None, max_length=500)
    phone: Optional[str] = Field(None, max_length=50)
    hours_json: Optional[str] = None
    photos: List[str] = Field(default_factory=list)
    audio_url_ru: Optional[str] = Field(None, max_length=500)
    audio_url_en: Optional[str] = Field(None, max_length=500)
    wheelchair_accessible: bool = False
    audio_description: bool = False


class PlaceCreate(PlaceBase):
    pass


class PlaceUpdate(BaseModel):
    title_ru: Optional[str] = Field(None, min_length=1, max_length=255)
    title_en: Optional[str] = Field(None, min_length=1, max_length=255)
    description_ru: Optional[str] = Field(None, min_length=1)
    description_en: Optional[str] = Field(None, min_length=1)
    category: Optional[PlaceCategory] = None
    subcategory: Optional[PlaceSubcategory] = None
    tags: Optional[List[str]] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    address_ru: Optional[str] = Field(None, max_length=500)
    address_en: Optional[str] = Field(None, max_length=500)
    price_tier: Optional[PriceTier] = None
    is_commercial: Optional[bool] = None
    website: Optional[str] = Field(None, max_length=500)
    phone: Optional[str] = Field(None, max_length=50)
    hours_json: Optional[str] = None
    photos: Optional[List[str]] = None
    audio_url_ru: Optional[str] = Field(None, max_length=500)
    audio_url_en: Optional[str] = Field(None, max_length=500)
    wheelchair_accessible: Optional[bool] = None
    audio_description: Optional[bool] = None


class PlaceResponse(PlaceBase):
    id: int
    rating_overall: float = 0.0
    rating_interest: float = 0.0
    rating_informativeness: float = 0.0
    rating_convenience: float = 0.0
    reviews_count: int = 0
    is_active: bool = True
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlaceListResponse(BaseModel):
    places: List[PlaceResponse]
    total: int
    page: int
    per_page: int
    has_next: bool