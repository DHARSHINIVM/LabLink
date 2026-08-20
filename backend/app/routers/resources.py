from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models.resource import Resource
from ..models.user import User
from ..schemas.resource import (
    ResourceCreate,
    ResourceResponse,
    ResourceUpdate,
)
from .auth import require_admin


# ============================================================================
# ROUTER
# ============================================================================

router = APIRouter(
    prefix="/api/resources",
    tags=["Resources"],
)


# ============================================================================
# GET ALL RESOURCES
# ============================================================================
# Public/student endpoint.
# Students need this to browse available laboratory resources.
# ============================================================================

@router.get(
    "",
    response_model=List[ResourceResponse],
)
def get_resources(
    db: Session = Depends(get_db),
):
    resources = (
        db.query(Resource)
        .order_by(Resource.id)
        .all()
    )

    return resources


# ============================================================================
# GET RESOURCE BY ID
# ============================================================================
# Public/student endpoint.
# ============================================================================

@router.get(
    "/{resource_id}",
    response_model=ResourceResponse,
)
def get_resource(
    resource_id: int,
    db: Session = Depends(get_db),
):
    resource = (
        db.query(Resource)
        .filter(
            Resource.id == resource_id
        )
        .first()
    )

    if resource is None:
        raise HTTPException(
            status_code=404,
            detail="Resource not found",
        )

    return resource


# ============================================================================
# CREATE RESOURCE
# ============================================================================
# ADMIN ONLY
# ============================================================================

@router.post(
    "",
    response_model=ResourceResponse,
    status_code=201,
)
def create_resource(
    resource_data: ResourceCreate,
    db: Session = Depends(get_db),

    # Authentication / authorization
    admin: User = Depends(require_admin),
):
    # ------------------------------------------------------------------------
    # VALIDATE QUANTITY
    # ------------------------------------------------------------------------

    if (
        resource_data.available_quantity
        > resource_data.quantity
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Available quantity cannot be "
                "greater than total quantity."
            ),
        )

    # ------------------------------------------------------------------------
    # CREATE RESOURCE
    # ------------------------------------------------------------------------

    resource = Resource(
        name=resource_data.name,
        category=resource_data.category,
        department=resource_data.department,
        location=resource_data.location,
        description=resource_data.description,
        quantity=resource_data.quantity,
        available_quantity=(
            resource_data.available_quantity
        ),
        utilization=resource_data.utilization,
        status=resource_data.status,
    )

    db.add(resource)
    db.commit()
    db.refresh(resource)

    return resource


# ============================================================================
# UPDATE RESOURCE
# ============================================================================
# ADMIN ONLY
# ============================================================================

@router.put(
    "/{resource_id}",
    response_model=ResourceResponse,
)
def update_resource(
    resource_id: int,
    resource_data: ResourceUpdate,
    db: Session = Depends(get_db),

    # Authentication / authorization
    admin: User = Depends(require_admin),
):
    # ------------------------------------------------------------------------
    # FIND RESOURCE
    # ------------------------------------------------------------------------

    resource = (
        db.query(Resource)
        .filter(
            Resource.id == resource_id
        )
        .first()
    )

    if resource is None:
        raise HTTPException(
            status_code=404,
            detail="Resource not found",
        )

    # ------------------------------------------------------------------------
    # GET ONLY PROVIDED FIELDS
    # ------------------------------------------------------------------------

    updates = resource_data.model_dump(
        exclude_unset=True
    )

    # ------------------------------------------------------------------------
    # DETERMINE FINAL QUANTITIES
    # ------------------------------------------------------------------------

    final_quantity = updates.get(
        "quantity",
        resource.quantity,
    )

    final_available_quantity = updates.get(
        "available_quantity",
        resource.available_quantity,
    )

    # ------------------------------------------------------------------------
    # VALIDATE QUANTITY
    # ------------------------------------------------------------------------

    if final_available_quantity < 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "Available quantity cannot be negative."
            ),
        )

    if final_quantity < 1:
        raise HTTPException(
            status_code=400,
            detail=(
                "Total quantity must be at least 1."
            ),
        )

    if (
        final_available_quantity
        > final_quantity
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Available quantity cannot be "
                "greater than total quantity."
            ),
        )

    # ------------------------------------------------------------------------
    # APPLY UPDATES
    # ------------------------------------------------------------------------

    for field, value in updates.items():
        setattr(
            resource,
            field,
            value,
        )

    # ------------------------------------------------------------------------
    # AUTOMATIC STATUS
    # ------------------------------------------------------------------------
    #
    # Inactive is a deliberate admin state.
    # Otherwise availability is derived from quantity.
    # ------------------------------------------------------------------------

    if resource.status != "Inactive":

        if resource.available_quantity <= 0:
            resource.status = "Unavailable"

        else:
            resource.status = "Available"

    # ------------------------------------------------------------------------
    # AUTOMATIC UTILIZATION
    # ------------------------------------------------------------------------

    if resource.quantity > 0:

        used_quantity = (
            resource.quantity
            - resource.available_quantity
        )

        resource.utilization = round(
            (
                used_quantity
                / resource.quantity
            )
            * 100,
            2,
        )

    # ------------------------------------------------------------------------
    # SAVE
    # ------------------------------------------------------------------------

    db.commit()
    db.refresh(resource)

    return resource


# ============================================================================
# DELETE RESOURCE
# ============================================================================
# ADMIN ONLY
# ============================================================================

@router.delete(
    "/{resource_id}",
)
def delete_resource(
    resource_id: int,
    db: Session = Depends(get_db),

    # Authentication / authorization
    admin: User = Depends(require_admin),
):
    # ------------------------------------------------------------------------
    # FIND RESOURCE
    # ------------------------------------------------------------------------

    resource = (
        db.query(Resource)
        .filter(
            Resource.id == resource_id
        )
        .first()
    )

    if resource is None:
        raise HTTPException(
            status_code=404,
            detail="Resource not found",
        )

    # ------------------------------------------------------------------------
    # DELETE
    # ------------------------------------------------------------------------

    db.delete(resource)
    db.commit()

    return {
        "message": "Resource deleted successfully",
        "resource_id": resource_id,
    }