from sqlalchemy import Column, String, Float, Integer, Boolean, Text, ARRAY, Enum, ForeignKey
from sqlalchemy.orm import relationship
import enum
from .base import BaseModel


class ReviewStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    HIDDEN = "hidden"


class Review(BaseModel):
    __tablename__ = "reviews"

    # Relationships
    place_id = Column(Integer, ForeignKey("places.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Content
    text = Column(Text, nullable=False)
    photos = Column(ARRAY(String), default=[])  # S3 URLs
    
    # Ratings
    rating_interest = Column(Float, nullable=False)
    rating_informativeness = Column(Float, nullable=False)
    rating_convenience = Column(Float, nullable=False)
    
    # Moderation
    status = Column(Enum(ReviewStatus), default=ReviewStatus.PENDING)
    moderation_notes = Column(Text, nullable=True)
    reports_count = Column(Integer, default=0)
    
    # AI moderation
    toxicity_score = Column(Float, nullable=True)  # Perspective API score
    spam_score = Column(Float, nullable=True)
    
    # Relationships
    place = relationship("Place", back_populates="reviews")
    user = relationship("User")