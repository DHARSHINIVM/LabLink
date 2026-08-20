from typing import List, Optional

from pydantic import BaseModel


class InventoryApplyItem(BaseModel):
    action: str

    existing_id: Optional[int] = None

    name: str
    category: Optional[str] = None
    quantity: Optional[int] = None
    location: Optional[str] = None
    department: Optional[str] = None
    description: Optional[str] = None


class InventoryApplyRequest(BaseModel):
    items: List[InventoryApplyItem]


class InventoryApplyResult(BaseModel):
    action: str

    resource_id: int

    name: str

    quantity: int

    available_quantity: int

    status: str


class InventoryApplyResponse(BaseModel):
    message: str

    applied_count: int

    results: List[InventoryApplyResult]