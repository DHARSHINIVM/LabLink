from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
)

from sqlalchemy.orm import Session

from ..database import get_db
from ..models.user import User
from ..schemas.inventory_import import (
    InventoryImportResponse,
)
from ..services.inventory_extractor import (
    extract_inventory,
)
from ..services.inventory_reconciliation import (
    reconcile_inventory,
)
from .auth import require_admin
from ..database import get_db
from ..models.resource import Resource
from ..schemas.inventory_apply import (
    InventoryApplyRequest,
    InventoryApplyResponse,
    InventoryApplyResult,
)
# ============================================================================
# ROUTER
# ============================================================================

router = APIRouter(
    prefix="/api/admin/inventory",
    tags=["Smart Inventory Sync"],
)


# ============================================================================
# CONFIGURATION
# ============================================================================

MAX_FILE_SIZE = (
    10 * 1024 * 1024
)

ALLOWED_CONTENT_TYPE = (
    "application/pdf"
)


# ============================================================================
# PREVIEW INVENTORY PDF
# ============================================================================

@router.post(
    "/preview",
    response_model=InventoryImportResponse,
)   
async def preview_inventory_pdf(
    file: UploadFile = File(...),

    admin: User = Depends(
        require_admin
    ),
):


    # ------------------------------------------------------------------------
    # FILE TYPE
    # ------------------------------------------------------------------------

    if file.content_type != (
        ALLOWED_CONTENT_TYPE
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Only PDF files are "
                "supported."
            ),
        )

    # ------------------------------------------------------------------------
    # READ FILE
    # ------------------------------------------------------------------------

    pdf_bytes = await file.read()

    # ------------------------------------------------------------------------
    # EMPTY FILE
    # ------------------------------------------------------------------------

    if not pdf_bytes:

        raise HTTPException(
            status_code=400,
            detail=(
                "Uploaded PDF is empty."
            ),
        )

    # ------------------------------------------------------------------------
    # FILE SIZE
    # ------------------------------------------------------------------------

    if len(pdf_bytes) > MAX_FILE_SIZE:

        raise HTTPException(
            status_code=400,
            detail=(
                "PDF file is too large. "
                "Maximum size is 10 MB."
            ),
        )

    # ------------------------------------------------------------------------
    # EXTRACT
    # ------------------------------------------------------------------------

    try:

        (
            resources,
            warnings,
            pages_processed,
            extraction_mode,
        ) = extract_inventory(
            pdf_bytes
        )

    except Exception as exc:

        raise HTTPException(
            status_code=422,
            detail=(
                "Unable to process "
                "the PDF: "
                f"{str(exc)}"
            ),
        )

    # ------------------------------------------------------------------------
    # NO RESOURCES
    # ------------------------------------------------------------------------

    if not resources:

        warnings.append(
            (
                "No resource records "
                "were extracted."
            )
        )

    # ------------------------------------------------------------------------
    # RESPONSE
    # ------------------------------------------------------------------------

    return InventoryImportResponse(

        filename=(
            file.filename
            or "inventory.pdf"
        ),

        extraction_mode=(
            extraction_mode
        ),

        pages_processed=(
            pages_processed
        ),

        resources_found=len(
            resources
        ),

        resources=resources,

        warnings=warnings,
    )
@router.post(
    "/reconcile",
)
async def reconcile_inventory_pdf(
    file: UploadFile = File(...),

    db: Session = Depends(get_db),

    admin: User = Depends(
        require_admin
    ),
):
    if file.content_type != "application/pdf":

        raise HTTPException(
            status_code=400,
            detail="Only PDF files are supported.",
        )

    pdf_bytes = await file.read()

    if not pdf_bytes:

        raise HTTPException(
            status_code=400,
            detail="Uploaded PDF is empty.",
        )

    if len(pdf_bytes) > MAX_FILE_SIZE:

        raise HTTPException(
            status_code=400,
            detail="PDF file is too large. Maximum size is 10 MB.",
        )

    try:

        (
            extracted_resources,
            extraction_warnings,
            pages_processed,
            extraction_mode,
        ) = extract_inventory(
            pdf_bytes
        )

    except Exception as exc:

        raise HTTPException(
            status_code=422,
            detail=f"Unable to process PDF: {str(exc)}",
        )

    items = reconcile_inventory(
        db,
        extracted_resources,
    )

    new_resources = sum(
        1
        for item in items
        if item.action == "NEW"
    )

    updated_resources = sum(
        1
        for item in items
        if item.action == "UPDATE"
    )

    unchanged_resources = sum(
        1
        for item in items
        if item.action == "UNCHANGED"
    )

    review_required = sum(
        1
        for item in items
        if item.confidence < 0.80
    )

    return {
        "filename": (
            file.filename
            or "inventory.pdf"
        ),

        "extraction_mode":
            extraction_mode,

        "pages_processed":
            pages_processed,

        "total_extracted":
            len(extracted_resources),

        "new_resources":
            new_resources,

        "updated_resources":
            updated_resources,

        "unchanged_resources":
            unchanged_resources,

        "review_required":
            review_required,

        "items":
            items,

        "warnings":
            extraction_warnings,
    }
# ============================================================================
# APPLY APPROVED INVENTORY CHANGES
# ============================================================================
#
# IMPORTANT:
# This endpoint only applies resources explicitly approved by the admin.
#
# NEW
#     -> Create resource
#
# UPDATE
#     -> Update existing resource
#
# Anything else
#     -> Rejected
#
# ============================================================================

@router.post(
    "/apply",
    response_model=InventoryApplyResponse,
)
def apply_inventory_changes(
    payload: InventoryApplyRequest,

    db: Session = Depends(get_db),

    admin: User = Depends(
        require_admin
    ),
):

    results = []

    try:

        # ====================================================================
        # PROCESS EACH APPROVED ITEM
        # ====================================================================

        for item in payload.items:

            action = (
                item.action
                .strip()
                .upper()
            )

            # ================================================================
            # NEW RESOURCE
            # ================================================================

            if action == "NEW":

                # ------------------------------------------------------------
                # VALIDATE REQUIRED QUANTITY
                # ------------------------------------------------------------

                if (
                    item.quantity is None
                    or item.quantity < 1
                ):
                    raise HTTPException(
                        status_code=400,
                        detail=(
                            f"Invalid quantity "
                            f"for new resource "
                            f"'{item.name}'."
                        ),
                    )

                # ------------------------------------------------------------
                # CHECK DUPLICATE AGAIN
                #
                # The database may have changed between reconciliation
                # and approval.
                # ------------------------------------------------------------

                existing = (
                    db.query(Resource)
                    .filter(
                        Resource.name.ilike(
                            item.name.strip()
                        )
                    )
                    .first()
                )

                if existing:

                    raise HTTPException(
                        status_code=409,
                        detail=(
                            f"Resource '{item.name}' "
                            f"already exists. "
                            f"Please reconcile again."
                        ),
                    )

                # ------------------------------------------------------------
                # CREATE
                # ------------------------------------------------------------

                resource = Resource(
                    name=item.name.strip(),

                    category=(
                        item.category
                        or "Uncategorized"
                    ),

                    department=(
                        item.department
                        or "Unknown"
                    ),

                    location=(
                        item.location
                        or "Unknown"
                    ),

                    description=(
                        item.description
                        or ""
                    ),

                    quantity=item.quantity,

                    available_quantity=(
                        item.quantity
                    ),

                    utilization=0,

                    status="Available",
                )

                db.add(resource)

                db.flush()

                results.append(
                    InventoryApplyResult(
                        action="CREATED",

                        resource_id=resource.id,

                        name=resource.name,

                        quantity=resource.quantity,

                        available_quantity=(
                            resource.available_quantity
                        ),

                        status=resource.status,
                    )
                )

            # ================================================================
            # UPDATE EXISTING RESOURCE
            # ================================================================

            elif action == "UPDATE":

                if item.existing_id is None:

                    raise HTTPException(
                        status_code=400,
                        detail=(
                            f"existing_id is required "
                            f"for update of "
                            f"'{item.name}'."
                        ),
                    )

                # ------------------------------------------------------------
                # LOCK RESOURCE
                # ------------------------------------------------------------

                resource = (
                    db.query(Resource)
                    .filter(
                        Resource.id
                        == item.existing_id
                    )
                    .with_for_update()
                    .first()
                )

                if resource is None:

                    raise HTTPException(
                        status_code=404,
                        detail=(
                            f"Resource ID "
                            f"{item.existing_id} "
                            f"no longer exists. "
                            f"Please reconcile again."
                        ),
                    )

                # ------------------------------------------------------------
                # QUANTITY VALIDATION
                # ------------------------------------------------------------

                if item.quantity is None:

                    new_quantity = (
                        resource.quantity
                    )

                else:

                    new_quantity = (
                        item.quantity
                    )

                if new_quantity < 1:

                    raise HTTPException(
                        status_code=400,
                        detail=(
                            f"Quantity for "
                            f"'{resource.name}' "
                            f"must be at least 1."
                        ),
                    )

                # ------------------------------------------------------------
                # PRESERVE CURRENTLY ISSUED ITEMS
                # ------------------------------------------------------------

                currently_in_use = max(
                    resource.quantity
                    - resource.available_quantity,
                    0,
                )

                if (
                    new_quantity
                    < currently_in_use
                ):

                    raise HTTPException(
                        status_code=409,
                        detail=(
                            f"Cannot reduce "
                            f"'{resource.name}' "
                            f"to {new_quantity}. "
                            f"{currently_in_use} "
                            f"units are currently "
                            f"in use."
                        ),
                    )

                # ------------------------------------------------------------
                # CALCULATE AVAILABLE
                # ------------------------------------------------------------

                new_available_quantity = (
                    new_quantity
                    - currently_in_use
                )

                # ------------------------------------------------------------
                # APPLY BASIC FIELDS
                # ------------------------------------------------------------

                resource.quantity = (
                    new_quantity
                )

                resource.available_quantity = (
                    new_available_quantity
                )

                if item.category is not None:
                    resource.category = (
                        item.category
                    )

                if item.location is not None:
                    resource.location = (
                        item.location
                    )

                if item.department is not None:
                    resource.department = (
                        item.department
                    )

                if item.description is not None:
                    resource.description = (
                        item.description
                    )

                # ------------------------------------------------------------
                # UTILIZATION
                # ------------------------------------------------------------

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

                else:

                    resource.utilization = 0

                # ------------------------------------------------------------
                # STATUS
                # ------------------------------------------------------------

                if resource.available_quantity <= 0:

                    resource.status = (
                        "Unavailable"
                    )

                elif resource.status != "Inactive":

                    resource.status = (
                        "Available"
                    )

                # ------------------------------------------------------------
                # RESULT
                # ------------------------------------------------------------

                results.append(
                    InventoryApplyResult(
                        action="UPDATED",

                        resource_id=resource.id,

                        name=resource.name,

                        quantity=resource.quantity,

                        available_quantity=(
                            resource.available_quantity
                        ),

                        status=resource.status,
                    )
                )

            # ================================================================
            # INVALID ACTION
            # ================================================================

            else:

                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"Invalid inventory "
                        f"action '{item.action}'. "
                        f"Use NEW or UPDATE."
                    ),
                )

        # ====================================================================
        # COMMIT EVERYTHING
        # ====================================================================

        db.commit()

    except HTTPException:

        db.rollback()

        raise

    except Exception as exc:

        db.rollback()

        raise HTTPException(
            status_code=500,
            detail=(
                "Inventory synchronization "
                f"failed: {str(exc)}"
            ),
        )

    # ========================================================================
    # RESPONSE
    # ========================================================================

    return InventoryApplyResponse(
        message=(
            "Inventory changes applied "
            "successfully."
        ),

        applied_count=len(
            results
        ),

        results=results,
    )