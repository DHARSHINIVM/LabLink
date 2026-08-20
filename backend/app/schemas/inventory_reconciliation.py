from typing import Any, Dict, List, Optional

from pydantic import BaseModel


class FieldChange(BaseModel):
    old: Any
    new: Any


class ReconciliationItem(BaseModel):
    action: str
    confidence: float

    existing_id: Optional[int] = None

    name: str
    category: Optional[str] = None
    quantity: Optional[int] = None
    location: Optional[str] = None
    department: Optional[str] = None
    description: Optional[str] = None

    changes: Dict[str, FieldChange] = {}

    current_in_use: int = 0

    proposed_available_quantity: Optional[int] = None

    reason: Optional[str] = None


class ReconciliationResponse(BaseModel):
    filename: str

    total_extracted: int

    new_resources: int

    updated_resources: int

    unchanged_resources: int

    review_required: int

    items: List[ReconciliationItem]

    warnings: List[str]