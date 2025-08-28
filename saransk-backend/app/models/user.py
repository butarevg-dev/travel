from sqlalchemy import Column, String, Boolean, JSON, Enum
import enum
from .base import BaseModel


class AuthProvider(str, enum.Enum):
    APPLE = "apple"
    EMAIL = "email"


class User(BaseModel):
    __tablename__ = "users"

    # Auth
    auth_provider = Column(Enum(AuthProvider), nullable=False)
    auth_id = Column(String(255), nullable=False, unique=True)  # Apple ID or email
    email = Column(String(255), nullable=True, unique=True)
    
    # Profile
    name = Column(String(255), nullable=True)
    language = Column(String(10), default="ru")  # ru, en
    
    # Preferences
    interests = Column(JSON, default=list)  # List of category/subcategory strings
    preferences = Column(JSON, default=dict)  # General preferences dict
    
    # Premium
    is_premium = Column(Boolean, default=False)
    premium_expires_at = Column(String(50), nullable=True)  # ISO string
    
    # Status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)