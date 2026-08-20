from typing import List, Optional

from pydantic import BaseModel


class ExtractedResource(BaseModel):
    name: str

    category: Optional[str] = None

    quantity: Optional[int] = None

    location: Optional[str] = None

    department: Optional[str] = None

    description: Optional[str] = None


class InventoryImportResponse(BaseModel):
    filename: str

    extraction_mode: str

    pages_processed: int

    resources_found: int

    resources: List[ExtractedResource]

    warnings: List[str]