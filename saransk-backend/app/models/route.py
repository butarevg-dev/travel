from sqlalchemy import Column, String, Integer, Boolean, JSON, ForeignKey, Float
from sqlalchemy.orm import relationship
from .base import BaseModel


class RouteTemplate(BaseModel):
    __tablename__ = "route_templates"

    # Basic info
    name_ru = Column(String(255), nullable=False)
    name_en = Column(String(255), nullable=False)
    description_ru = Column(String(1000), nullable=True)
    description_en = Column(String(1000), nullable=True)
    
    # Route properties
    duration_minutes = Column(Integer, nullable=False)  # Estimated duration
    distance_km = Column(Float, nullable=True)
    place_ids = Column(JSON, nullable=False)  # List of place IDs in order
    
    # Categories and tags
    categories = Column(JSON, default=list)  # List of categories
    tags = Column(JSON, default=list)  # List of tags
    
    # Premium
    is_premium = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    
    # Status
    is_active = Column(Boolean, default=True)


class GeneratedRoute(BaseModel):
    __tablename__ = "generated_routes"

    # User who generated this route
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Route properties
    duration_minutes = Column(Integer, nullable=False)
    distance_km = Column(Float, nullable=True)
    place_ids = Column(JSON, nullable=False)  # List of place IDs in order
    
    # Generation parameters
    interests = Column(JSON, default=list)  # User interests used
    constraints = Column(JSON, default=dict)  # Generation constraints
    
    # Route data (serialized for offline use)
    route_data = Column(JSON, nullable=True)  # Full route object
    offline_pack_id = Column(String(255), nullable=True)  # Reference to offline pack
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User")