from datetime import datetime

from pydantic import BaseModel


# ============================================================================
# CREATE REQUEST
# ============================================================================

class RequestCreate(BaseModel):
    resource_id: int
    requester_id: int
    purpose: str


# ============================================================================
# REQUEST RESPONSE
# ============================================================================

class RequestResponse(BaseModel):
    id: int

    resource_id: int

    requester_id: int

    status: str

    purpose: str

    requested_at: datetime

    reviewed_at: datetime | None = None

    class Config:
        from_attributes = True