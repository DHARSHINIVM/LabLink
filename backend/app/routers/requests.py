from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.resource import Resource
from app.models.resource_request import ResourceRequest
from app.models.user import User
from app.schemas.request import (
    RequestCreate,
    RequestResponse,
)

router = APIRouter(
    prefix="/api/requests",
    tags=["Requests"],
)


# ============================================================================
# CREATE REQUEST
# ============================================================================

@router.post(
    "",
    response_model=RequestResponse,
)
def create_request(
    request: RequestCreate,
    db: Session = Depends(get_db),
):
    resource = (
        db.query(Resource)
        .filter(Resource.id == request.resource_id)
        .first()
    )

    if not resource:
        raise HTTPException(
            status_code=404,
            detail="Resource not found",
        )

    user = (
        db.query(User)
        .filter(User.id == request.requester_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Requester not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="User account is inactive",
        )

    if resource.available_quantity <= 0:
        raise HTTPException(
            status_code=400,
            detail="Resource is currently unavailable",
        )

    # Prevent duplicate pending requests
    existing_request = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.resource_id == request.resource_id,
            ResourceRequest.requester_id == request.requester_id,
            ResourceRequest.status == "Pending",
        )
        .first()
    )

    if existing_request:
        raise HTTPException(
            status_code=400,
            detail=(
                "You already have a pending request "
                "for this resource"
            ),
        )

    new_request = ResourceRequest(
        resource_id=request.resource_id,
        requester_id=request.requester_id,
        status="Pending",
        purpose=request.purpose,
        requested_at=datetime.now(),
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return new_request


# ============================================================================
# GET ALL REQUESTS
# ============================================================================
# Used by admin/general request management.

@router.get(
    "",
    response_model=list[RequestResponse],
)
def get_requests(
    db: Session = Depends(get_db),
):
    return (
        db.query(ResourceRequest)
        .order_by(
            ResourceRequest.requested_at.desc()
        )
        .all()
    )


# ============================================================================
# GET REQUESTS FOR ONE STUDENT
# ============================================================================

@router.get(
    "/user/{user_id}",
    response_model=list[RequestResponse],
)
def get_user_requests(
    user_id: int,
    db: Session = Depends(get_db),
):
    # Make sure user exists
    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    requests = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.requester_id == user_id
        )
        .order_by(
            ResourceRequest.requested_at.desc()
        )
        .all()
    )

    return requests