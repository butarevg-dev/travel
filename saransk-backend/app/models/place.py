from sqlalchemy import Column, String, Float, Integer, Boolean, Text, ARRAY, Enum
from sqlalchemy.orm import relationship
import enum
from .base import BaseModel


class PlaceCategory(str, enum.Enum):
    MONUMENT = "monument"
    ARCHITECTURE = "architecture"
    FOOD = "food"
    SOUVENIR = "souvenir"


class PlaceSubcategory(str, enum.Enum):
    # Monuments
    HISTORICAL_PERSON = "historical_person"
    MILITARY_GLORY = "military_glory"
    CULTURAL_HERITAGE = "cultural_heritage"
    
    # Architecture
    ORTHODOX_CHURCH = "orthodox_church"
    MODERN = "modern"
    SOVIET_MODERNISM = "soviet_modernism"
    WOODEN_ARCHITECTURE = "wooden_architecture"
    CONTEMPORARY = "contemporary"
    
    # Food
    MORDOVIAN_CUISINE = "mordovian_cuisine"
    CAFE = "cafe"
    RESTAURANT = "restaurant"
    STREET_FOOD = "street_food"
    COFFEE_SHOP = "coffee_shop"
    VEGETARIAN = "vegetarian"
    
    # Souvenirs
    CRAFTS_ETHNO = "crafts_ethno"
    OFFICIAL_STORE = "official_store"
    MARKET_FAIR = "market_fair"
    WORKSHOP = "workshop"


class PriceTier(str, enum.Enum):
    FREE = "free"
    BUDGET = "budget"
    MEDIUM = "medium"
    PREMIUM = "premium"


class Place(BaseModel):
    __tablename__ = "places"

    # Basic info (bilingual)
    title_ru = Column(String(255), nullable=False)
    title_en = Column(String(255), nullable=False)
    description_ru = Column(Text, nullable=False)
    description_en = Column(Text, nullable=False)
    
    # Categories
    category = Column(Enum(PlaceCategory), nullable=False)
    subcategory = Column(Enum(PlaceSubcategory), nullable=False)
    tags = Column(ARRAY(String), default=[])
    
    # Location
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address_ru = Column(String(500), nullable=True)
    address_en = Column(String(500), nullable=True)
    
    # Business info
    price_tier = Column(Enum(PriceTier), default=PriceTier.FREE)
    is_commercial = Column(Boolean, default=False)
    website = Column(String(500), nullable=True)
    phone = Column(String(50), nullable=True)
    
    # Hours (JSON string for now, could be separate table)
    hours_json = Column(Text, nullable=True)
    
    # Media
    photos = Column(ARRAY(String), default=[])  # S3 URLs
    audio_url_ru = Column(String(500), nullable=True)
    audio_url_en = Column(String(500), nullable=True)
    
    # Accessibility
    wheelchair_accessible = Column(Boolean, default=False)
    audio_description = Column(Boolean, default=False)
    
    # Ratings (calculated from reviews)
    rating_overall = Column(Float, default=0.0)
    rating_interest = Column(Float, default=0.0)
    rating_informativeness = Column(Float, default=0.0)
    rating_convenience = Column(Float, default=0.0)
    reviews_count = Column(Integer, default=0)
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Relationships
    reviews = relationship("Review", back_populates="place", cascade="all, delete-orphan")