from typing import List, Optional

from sqlalchemy.orm import Session

from ..models.resource import Resource
from ..schemas.inventory_import import ExtractedResource
from ..schemas.inventory_reconciliation import (
    FieldChange,
    ReconciliationItem,
)


# ============================================================================
# NORMALIZATION
# ============================================================================

def normalize_name(
    value: Optional[str],
) -> str:

    if not value:
        return ""

    value = value.lower().strip()

    # Remove punctuation
    import re

    value = re.sub(
        r"[^a-z0-9\s]",
        "",
        value,
    )

    # Normalize whitespace
    value = re.sub(
        r"\s+",
        " ",
        value,
    )

    return value


# ============================================================================
# FIND EXISTING RESOURCE
# ============================================================================

def find_matching_resource(
    db: Session,
    extracted: ExtractedResource,
) -> Optional[Resource]:

    normalized_name = normalize_name(
        extracted.name
    )

    resources = (
        db.query(Resource)
        .all()
    )

    # ------------------------------------------------------------------------
    # FIRST: EXACT NORMALIZED NAME MATCH
    # ------------------------------------------------------------------------

    for resource in resources:

        existing_name = normalize_name(
            resource.name
        )

        if existing_name == normalized_name:

            return resource

    # ------------------------------------------------------------------------
    # SECOND: NAME + CATEGORY MATCH
    # ------------------------------------------------------------------------

    extracted_category = normalize_name(
        extracted.category
    )

    if extracted_category:

        for resource in resources:

            existing_name = normalize_name(
                resource.name
            )

            existing_category = normalize_name(
                resource.category
            )

            if (
                existing_name
                == normalized_name
                and
                existing_category
                == extracted_category
            ):

                return resource

    return None


# ============================================================================
# CURRENTLY IN USE
# ============================================================================

def calculate_currently_in_use(
    resource: Resource,
) -> int:

    if resource.quantity is None:
        return 0

    if resource.available_quantity is None:
        return 0

    return max(
        resource.quantity
        - resource.available_quantity,
        0,
    )


# ============================================================================
# COMPARE RESOURCE
# ============================================================================

def reconcile_resource(
    db: Session,
    extracted: ExtractedResource,
) -> ReconciliationItem:

    existing = find_matching_resource(
        db,
        extracted,
    )

    # =========================================================================
    # NEW RESOURCE
    # =========================================================================

    if existing is None:

        return ReconciliationItem(
            action="NEW",

            confidence=0.95,

            existing_id=None,

            name=extracted.name,

            category=extracted.category,

            quantity=extracted.quantity,

            location=extracted.location,

            department=extracted.department,

            description=extracted.description,

            changes={},

            current_in_use=0,

            proposed_available_quantity=(
                extracted.quantity
                if extracted.quantity is not None
                else None
            ),

            reason=(
                "Resource was found in "
                "the uploaded inventory but "
                "does not currently exist "
                "in LabLink."
            ),
        )

    # =========================================================================
    # EXISTING RESOURCE
    # =========================================================================

    changes = {}

    # -------------------------------------------------------------------------
    # QUANTITY
    # -------------------------------------------------------------------------

    if (
        extracted.quantity is not None
        and
        extracted.quantity
        != existing.quantity
    ):

        changes["quantity"] = FieldChange(
            old=existing.quantity,
            new=extracted.quantity,
        )

    # -------------------------------------------------------------------------
    # CATEGORY
    # -------------------------------------------------------------------------

    if (
        extracted.category
        and
        extracted.category
        != existing.category
    ):

        changes["category"] = FieldChange(
            old=existing.category,
            new=extracted.category,
        )

    # -------------------------------------------------------------------------
    # LOCATION
    # -------------------------------------------------------------------------

    if (
        extracted.location
        and
        extracted.location
        != existing.location
    ):

        changes["location"] = FieldChange(
            old=existing.location,
            new=extracted.location,
        )

    # -------------------------------------------------------------------------
    # DEPARTMENT
    # -------------------------------------------------------------------------

    if (
        extracted.department
        and
        extracted.department
        != existing.department
    ):

        changes["department"] = FieldChange(
            old=existing.department,
            new=extracted.department,
        )

    # -------------------------------------------------------------------------
    # DESCRIPTION
    # -------------------------------------------------------------------------

    if (
        extracted.description
        and
        extracted.description
        != existing.description
    ):

        changes["description"] = FieldChange(
            old=existing.description,
            new=extracted.description,
        )

    # -------------------------------------------------------------------------
    # CURRENTLY IN USE
    # -------------------------------------------------------------------------

    current_in_use = (
        calculate_currently_in_use(
            existing
        )
    )

    # -------------------------------------------------------------------------
    # PROPOSED AVAILABLE
    # -------------------------------------------------------------------------

    proposed_available = (
        existing.available_quantity
    )

    if extracted.quantity is not None:

        if (
            extracted.quantity
            >= current_in_use
        ):

            proposed_available = (
                extracted.quantity
                - current_in_use
            )

        else:

            proposed_available = 0

    # =========================================================================
    # UNCHANGED
    # =========================================================================

    if not changes:

        return ReconciliationItem(

            action="UNCHANGED",

            confidence=0.99,

            existing_id=existing.id,

            name=existing.name,

            category=existing.category,

            quantity=existing.quantity,

            location=existing.location,

            department=existing.department,

            description=existing.description,

            changes={},

            current_in_use=current_in_use,

            proposed_available_quantity=(
                existing.available_quantity
            ),

            reason=(
                "Uploaded inventory matches "
                "the existing resource."
            ),
        )

    # =========================================================================
    # UPDATE
    # =========================================================================

    return ReconciliationItem(

        action="UPDATE",

        confidence=0.98,

        existing_id=existing.id,

        name=existing.name,

        category=(
            extracted.category
            or existing.category
        ),

        quantity=(
            extracted.quantity
            if extracted.quantity is not None
            else existing.quantity
        ),

        location=(
            extracted.location
            or existing.location
        ),

        department=(
            extracted.department
            or existing.department
        ),

        description=(
            extracted.description
            or existing.description
        ),

        changes=changes,

        current_in_use=current_in_use,

        proposed_available_quantity=(
            proposed_available
        ),

        reason=(
            "Existing resource was found "
            "but one or more inventory "
            "fields have changed."
        ),
    )


# ============================================================================
# RECONCILE ALL
# ============================================================================

def reconcile_inventory(
    db: Session,
    resources: List[ExtractedResource],
) -> List[ReconciliationItem]:

    results = []

    for resource in resources:

        result = reconcile_resource(
            db,
            resource,
        )

        results.append(result)

    return results