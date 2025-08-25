from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.db import get_db
from app.models.review import Review, ReviewStatus
from app.models.place import Place
from app.schemas.review import ReviewResponse, ReviewCreate, ReviewUpdate

router = APIRouter()


@router.get("/place/{place_id}", response_model=List[ReviewResponse])
async def get_place_reviews(
    place_id: int,
    db: Session = Depends(get_db),
    status: ReviewStatus = ReviewStatus.APPROVED,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
):
    """Get reviews for a specific place"""
    # Check if place exists
    place = db.query(Place).filter(Place.id == place_id, Place.is_active == True).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    query = db.query(Review).filter(
        Review.place_id == place_id,
        Review.status == status
    )
    
    reviews = query.offset((page - 1) * per_page).limit(per_page).all()
    return reviews


@router.post("/", response_model=ReviewResponse)
async def create_review(
    review_data: ReviewCreate,
    db: Session = Depends(get_db),
    # TODO: user_id: int = Depends(get_current_user_id)
):
    """Create a new review"""
    # TODO: Add user authentication
    user_id = 1  # Temporary placeholder
    
    # Check if place exists
    place = db.query(Place).filter(Place.id == review_data.place_id, Place.is_active == True).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
    
    # TODO: Check if user already reviewed this place
    
    # TODO: Add Perspective API moderation
    toxicity_score = None  # await check_toxicity(review_data.text)
    
    review = Review(
        **review_data.model_dump(),
        user_id=user_id,
        status=ReviewStatus.PENDING,
        toxicity_score=toxicity_score
    )
    
    db.add(review)
    db.commit()
    db.refresh(review)
    
    # TODO: Update place ratings
    # await update_place_ratings(place_id=review_data.place_id, db=db)
    
    return review


@router.put("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: int,
    review_data: ReviewUpdate,
    db: Session = Depends(get_db),
    # TODO: user_id: int = Depends(get_current_user_id)
):
    """Update a review (owner only)"""
    # TODO: Add user authentication
    user_id = 1  # Temporary placeholder
    
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    if review.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this review")
    
    if review.status != ReviewStatus.PENDING:
        raise HTTPException(status_code=400, detail="Cannot update approved/rejected review")
    
    update_data = review_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(review, field, value)
    
    # TODO: Re-check toxicity if text changed
    if "text" in update_data:
        toxicity_score = None  # await check_toxicity(review_data.text)
        review.toxicity_score = toxicity_score
        review.status = ReviewStatus.PENDING  # Reset to pending for re-moderation
    
    db.commit()
    db.refresh(review)
    return review


@router.delete("/{review_id}")
async def delete_review(
    review_id: int,
    db: Session = Depends(get_db),
    # TODO: user_id: int = Depends(get_current_user_id)
):
    """Delete a review (owner or admin only)"""
    # TODO: Add user authentication
    user_id = 1  # Temporary placeholder
    
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    if review.user_id != user_id:
        # TODO: Check if user is admin
        raise HTTPException(status_code=403, detail="Not authorized to delete this review")
    
    db.delete(review)
    db.commit()
    
    # TODO: Update place ratings
    # await update_place_ratings(place_id=review.place_id, db=db)
    
    return {"message": "Review deleted successfully"}


@router.post("/{review_id}/report")
async def report_review(
    review_id: int,
    reason: str,
    db: Session = Depends(get_db),
    # TODO: user_id: int = Depends(get_current_user_id)
):
    """Report a review for moderation"""
    # TODO: Add user authentication
    
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    review.reports_count += 1
    
    # Auto-hide if too many reports
    if review.reports_count >= 3:
        review.status = ReviewStatus.HIDDEN
    
    db.commit()
    return {"message": "Review reported successfully"}