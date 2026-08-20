from fastapi import FastAPI

from .database import Base, engine
from .models import Resource, ResourceRequest, User
from .routers.resources import router as resources_router
from .routers.requests import router as requests_router
from .routers.auth import router as auth_router
from .routers.admin import router as admin_router
from .routers.inventory_import import (
    router as inventory_import_router,
)
# ---------------------------------------------------------------------------
# DATABASE INITIALIZATION
# ---------------------------------------------------------------------------

Base.metadata.create_all(bind=engine)


# ---------------------------------------------------------------------------
# FASTAPI APPLICATION
# ---------------------------------------------------------------------------

app = FastAPI(
    title="LabLink API",
    description=(
        "Backend API for the LabLink institutional "
        "resource sharing platform."
    ),
    version="1.0.0",
)


# ---------------------------------------------------------------------------
# ROUTERS
# ---------------------------------------------------------------------------

app.include_router(resources_router)
app.include_router(requests_router)
app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(
    inventory_import_router
)
# ---------------------------------------------------------------------------
# ROOT
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    return {
        "message": "LabLink API is running",
        "version": "1.0.0",
    }


# ---------------------------------------------------------------------------
# HEALTH CHECK
# ---------------------------------------------------------------------------

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "LabLink Backend",
        "database": "connected",
    }