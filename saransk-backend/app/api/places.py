from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.db import get_db
from app.models.place import Place, PlaceCategory, PlaceSubcategory, PriceTier
from app.schemas.place import PlaceResponse, PlaceListResponse, PlaceCreate, PlaceUpdate

router = APIRouter()


@router.get("/", response_model=PlaceListResponse)
async def get_places(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    category: Optional[PlaceCategory] = None,
    subcategory: Optional[PlaceSubcategory] = None,
    price_tier: Optional[PriceTier] = None,
    is_commercial: Optional[bool] = None,
    is_active: bool = True,
):
    """Get list of places with filtering and pagination"""
    query = db.query(Place)
    
    if category:
        query = query.filter(Place.category == category)
    if subcategory:
        query = query.filter(Place.subcategory == subcategory)
    if price_tier:
        query = query.filter(Place.price_tier == price_tier)
    if is_commercial is not None:
        query = query.filter(Place.is_commercial == is_commercial)
    if is_active is not None:
        query = query.filter(Place.is_active == is_active)
    
    total = query.count()
    places = query.offset((page - 1) * per_page).limit(per_page).all()
    
    return PlaceListResponse(
        places=places,
        total=total,
        page=page,
        per_page=per_page,
        has_next=page * per_page < total
    )


@router.get("/{place_id}", response_model=PlaceResponse)
async def get_place(place_id: int, db: Session = Depends(get_db)):
    """Get a specific place by ID"""
    place = db.query(Place).filter(Place.id == place_id, Place.is_active == True).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    return place


@router.post("/", response_model=PlaceResponse)
async def create_place(place_data: PlaceCreate, db: Session = Depends(get_db)):
    """Create a new place (admin only)"""
    # TODO: Add admin authentication
    place = Place(**place_data.model_dump())
    db.add(place)
    db.commit()
    db.refresh(place)
    return place


@router.put("/{place_id}", response_model=PlaceResponse)
async def update_place(
    place_id: int, 
    place_data: PlaceUpdate, 
    db: Session = Depends(get_db)
):
    """Update a place (admin only)"""
    # TODO: Add admin authentication
    place = db.query(Place).filter(Place.id == place_id).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    update_data = place_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(place, field, value)
    
    db.commit()
    db.refresh(place)
    return place


@router.delete("/{place_id}")
async def delete_place(place_id: int, db: Session = Depends(get_db)):
    """Delete a place (admin only)"""
    # TODO: Add admin authentication
    place = db.query(Place).filter(Place.id == place_id).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    db.delete(place)
    db.commit()
    return {"message": "Place deleted successfully"}