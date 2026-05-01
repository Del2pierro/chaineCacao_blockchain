from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from api.v1.endpoints import lots, traceability, actors, audit
from database import init_db

# Initialize Database tables
try:
    init_db()
except Exception as e:
    print(f"Database initialization skipped or failed: {e}")

app = FastAPI(
    title="ChainCacao API",
    description="Backend API for Togo Cocoa & Coffee Traceability (Hyperledger Fabric)",
    version="2.0.0"
)


# CORS Configuration for Flutter, React, and local HTML testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Autorise toutes les origines pour le développement
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include Routers
app.include_router(actors.router, prefix="/api/v1/actors", tags=["Actors"])
app.include_router(lots.router, prefix="/api/v1/lots", tags=["Lots"])
app.include_router(traceability.router, prefix="/api/v1/traceability", tags=["Traceability"])
app.include_router(audit.router, prefix="/api/v1/audit", tags=["Audit & Queries"])

@app.get("/")
async def root():
    return {
        "message": "Welcome to ChainCacao API",
        "status": "Running",
        "docs": "/docs"
    }
