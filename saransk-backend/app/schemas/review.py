from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from app.models.review import ReviewStatus


class ReviewBase(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    photos: List[str] = Field(default_factory=list)
    rating_interest: float = Field(..., ge=1, le=5)
    rating_informativeness: float = Field(..., ge=1, le=5)
    rating_convenience: float = Field(..., ge=1, le=5)


class ReviewCreate(ReviewBase):
    place_id: int


class ReviewUpdate(BaseModel):
    text: Optional[str] = Field(None, min_length=1, max_length=2000)
    photos: Optional[List[str]] = None
    rating_interest: Optional[float] = Field(None, ge=1, le=5)
    rating_informativeness: Optional[float] = Field(None, ge=1, le=5)
    rating_convenience: Optional[float] = Field(None, ge=1, le=5)


class ReviewResponse(ReviewBase):
    id: int
    place_id: int
    user_id: int
    status: ReviewStatus
    moderation_notes: Optional[str] = None
    reports_count: int = 0
    toxicity_score: Optional[float] = None
    spam_score: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True