from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.resource import Resource
from app.models.resource_request import ResourceRequest
from app.models.user import User
from app.routers.auth import require_admin


router = APIRouter(
    prefix="/api/admin",
    tags=["Admin"],
)


# ============================================================================
# ADMIN DASHBOARD
# ============================================================================

@router.get("/dashboard")
def get_admin_dashboard(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    total_resources = (
        db.query(Resource).count()
    )

    available_resources = (
        db.query(Resource)
        .filter(
            Resource.available_quantity > 0
        )
        .count()
    )

    total_users = (
        db.query(User)
        .filter(
            User.is_active == True
        )
        .count()
    )

    pending_requests = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.status == "Pending"
        )
        .count()
    )

    approved_requests = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.status == "Approved"
        )
        .count()
    )

    completed_requests = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.status == "Completed"
        )
        .count()
    )

    rejected_requests = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.status == "Rejected"
        )
        .count()
    )

    return {
        "total_resources": total_resources,
        "available_resources": available_resources,
        "total_users": total_users,
        "pending_requests": pending_requests,
        "approved_requests": approved_requests,
        "completed_requests": completed_requests,
        "rejected_requests": rejected_requests,
    }


# ============================================================================
# GET ALL REQUESTS FOR ADMIN
# ============================================================================

@router.get("/requests")
def get_admin_requests(
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    requests = (
        db.query(ResourceRequest)
        .order_by(
            ResourceRequest.requested_at.desc()
        )
        .all()
    )

    result = []

    for request in requests:

        resource = (
            db.query(Resource)
            .filter(
                Resource.id ==
                request.resource_id
            )
            .first()
        )

        requester = (
            db.query(User)
            .filter(
                User.id ==
                request.requester_id
            )
            .first()
        )

        result.append({
            "id": request.id,

            "resource_id":
                request.resource_id,

            "resource_name": (
                resource.name
                if resource
                else "Unknown Resource"
            ),

            "requester_id":
                request.requester_id,

            "requester_name": (
                requester.name
                if requester
                else "Unknown User"
            ),

            "requester_department": (
                requester.department
                if requester
                else "Unknown"
            ),

            "status":
                request.status,

            "purpose":
                request.purpose,

            "requested_at":
                request.requested_at,

            "reviewed_at":
                request.reviewed_at,
        })

    return result


# ============================================================================
# UPDATE REQUEST STATUS
# ============================================================================
#
# WORKFLOW
#
# Pending
#    ├── Approved  → available_quantity - 1
#    └── Rejected  → no inventory change
#
# Approved
#    └── Completed → available_quantity + 1
#
# Completed / Rejected
#    └── Cannot be changed
#
# ============================================================================

@router.patch(
    "/requests/{request_id}/status"
)
def update_request_status(
    request_id: int,
    status: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    # ------------------------------------------------------------------------
    # NORMALIZE STATUS
    # ------------------------------------------------------------------------

    status = status.strip().capitalize()

    allowed_statuses = {
        "Pending",
        "Approved",
        "Rejected",
        "Completed",
    }

    if status not in allowed_statuses:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid status. "
                "Use Pending, Approved, "
                "Rejected, or Completed."
            ),
        )

    # ------------------------------------------------------------------------
    # FIND REQUEST
    # ------------------------------------------------------------------------

    request = (
        db.query(ResourceRequest)
        .filter(
            ResourceRequest.id ==
            request_id
        )
        .with_for_update()
        .first()
    )

    if request is None:
        raise HTTPException(
            status_code=404,
            detail="Request not found",
        )

    # ------------------------------------------------------------------------
    # GET RESOURCE
    #
    # Lock the resource row as well.
    #
    # This prevents two admins/processes from approving requests for
    # the final available item at the same time.
    # ------------------------------------------------------------------------

    resource = (
        db.query(Resource)
        .filter(
            Resource.id ==
            request.resource_id
        )
        .with_for_update()
        .first()
    )

    if resource is None:
        raise HTTPException(
            status_code=404,
            detail="Resource associated with request not found",
        )

    # ------------------------------------------------------------------------
    # CURRENT STATUS
    # ------------------------------------------------------------------------

    current_status = request.status

    # ------------------------------------------------------------------------
    # NO-OP
    # ------------------------------------------------------------------------

    if current_status == status:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Request is already "
                f"{current_status}."
            ),
        )

    # ------------------------------------------------------------------------
    # COMPLETED REQUESTS ARE FINAL
    # ------------------------------------------------------------------------

    if current_status == "Completed":
        raise HTTPException(
            status_code=400,
            detail=(
                "Completed requests "
                "cannot be changed."
            ),
        )

    # ------------------------------------------------------------------------
    # REJECTED REQUESTS ARE FINAL
    # ------------------------------------------------------------------------

    if current_status == "Rejected":
        raise HTTPException(
            status_code=400,
            detail=(
                "Rejected requests "
                "cannot be changed."
            ),
        )

    # =========================================================================
    # PENDING → APPROVED
    # =========================================================================

    if (
        current_status == "Pending"
        and status == "Approved"
    ):

        # ---------------------------------------------------------------------
        # CHECK RESOURCE STATUS
        # ---------------------------------------------------------------------

        if resource.status == "Inactive":
            raise HTTPException(
                status_code=400,
                detail=(
                    "This resource is inactive "
                    "and cannot be approved."
                ),
            )

        # ---------------------------------------------------------------------
        # CHECK INVENTORY
        # ---------------------------------------------------------------------

        if resource.available_quantity <= 0:

            raise HTTPException(
                status_code=400,
                detail=(
                    "Resource is no longer "
                    "available for approval."
                ),
            )

        # ---------------------------------------------------------------------
        # RESERVE ONE RESOURCE
        # ---------------------------------------------------------------------

        resource.available_quantity -= 1

        # ---------------------------------------------------------------------
        # RECALCULATE UTILIZATION
        # ---------------------------------------------------------------------

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

        # ---------------------------------------------------------------------
        # UPDATE RESOURCE STATUS
        # ---------------------------------------------------------------------

        if resource.available_quantity <= 0:
            resource.status = "Unavailable"
        else:
            resource.status = "Available"

        # ---------------------------------------------------------------------
        # APPROVE REQUEST
        # ---------------------------------------------------------------------

        request.status = "Approved"
        request.reviewed_at = datetime.now()

    # =========================================================================
    # PENDING → REJECTED
    # =========================================================================

    elif (
        current_status == "Pending"
        and status == "Rejected"
    ):

        # No inventory change.
        #
        # The resource was never reserved because the request
        # was only pending.

        request.status = "Rejected"
        request.reviewed_at = datetime.now()

    # =========================================================================
    # APPROVED → COMPLETED
    # =========================================================================

    elif (
        current_status == "Approved"
        and status == "Completed"
    ):

        # ---------------------------------------------------------------------
        # RETURN RESOURCE TO INVENTORY
        # ---------------------------------------------------------------------

        if resource.available_quantity < resource.quantity:

            resource.available_quantity += 1

        # ---------------------------------------------------------------------
        # RECALCULATE UTILIZATION
        # ---------------------------------------------------------------------

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

        # ---------------------------------------------------------------------
        # UPDATE RESOURCE STATUS
        # ---------------------------------------------------------------------

        if resource.status != "Inactive":

            if resource.available_quantity <= 0:
                resource.status = "Unavailable"
            else:
                resource.status = "Available"

        # ---------------------------------------------------------------------
        # COMPLETE REQUEST
        # ---------------------------------------------------------------------

        request.status = "Completed"
        request.reviewed_at = datetime.now()

    # =========================================================================
    # INVALID TRANSITION
    # =========================================================================

    else:

        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid status transition: "
                f"{current_status} → {status}"
            ),
        )

    # ------------------------------------------------------------------------
    # COMMIT EVERYTHING TOGETHER
    # ------------------------------------------------------------------------

    try:

        db.commit()

        db.refresh(request)
        db.refresh(resource)

    except Exception:

        db.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Failed to update request "
                "and resource inventory."
            ),
        )

    # ------------------------------------------------------------------------
    # RESPONSE
    # ------------------------------------------------------------------------

    return {
        "message":
            "Request status updated successfully",

        "request_id":
            request.id,

        "status":
            request.status,

        "reviewed_at":
            request.reviewed_at,

        "resource": {
            "id":
                resource.id,

            "name":
                resource.name,

            "quantity":
                resource.quantity,

            "available_quantity":
                resource.available_quantity,

            "utilization":
                resource.utilization,

            "status":
                resource.status,
        },
    }