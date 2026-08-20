from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


# ============================================================================
# CREATE RESOURCE
# ============================================================================

class ResourceCreate(BaseModel):
    name: str = Field(
        min_length=1,
        max_length=150,
    )

    category: str = Field(
        min_length=1,
        max_length=100,
    )

    department: str = Field(
        min_length=1,
        max_length=120,
    )

    location: str = Field(
        min_length=1,
        max_length=150,
    )

    description: str = ""

    quantity: int = Field(
        default=1,
        ge=1,
    )

    available_quantity: int = Field(
        default=1,
        ge=0,
    )

    utilization: float = Field(
        default=0.0,
        ge=0,
        le=100,
    )

    status: str = "Available"


# ============================================================================
# UPDATE RESOURCE
# ============================================================================

class ResourceUpdate(BaseModel):
    name: str | None = Field(
        default=None,
        min_length=1,
        max_length=150,
    )

    category: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
    )

    department: str | None = Field(
        default=None,
        min_length=1,
        max_length=120,
    )

    location: str | None = Field(
        default=None,
        min_length=1,
        max_length=150,
    )

    description: str | None = None

    quantity: int | None = Field(
        default=None,
        ge=1,
    )

    available_quantity: int | None = Field(
        default=None,
        ge=0,
    )

    utilization: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )

    status: str | None = None


# ============================================================================
# RESOURCE RESPONSE
# ============================================================================

class ResourceResponse(BaseModel):
    id: int

    name: str

    category: str

    department: str

    location: str

    description: str

    quantity: int

    available_quantity: int

    utilization: float

    status: str

    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )