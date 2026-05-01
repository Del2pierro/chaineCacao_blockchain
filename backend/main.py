from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from api.v1.endpoints import lots, traceability, actors, audit
from database import init_db

# Initialize Database tables
try:
    init_db()
except Exception as e:
    import traceback
    print("Database initialization skipped or failed.")
    # Try to print error without encoding issues
    try:
        print(f"Error: {str(e)}")
    except:
        print("Could not even print the error message due to encoding.")

from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
import traceback

class SafeEncodingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        try:
            return await call_next(request)
        except Exception as e:
            try:
                error_msg = str(e)
            except UnicodeDecodeError:
                error_msg = repr(e)
            safe_msg = error_msg.encode('utf-8', 'replace').decode('utf-8')
            print(f"GLOBAL ERROR CAUGHT: {safe_msg}")
            return JSONResponse(
                status_code=500,
                content={"success": False, "error": safe_msg}
            )

app = FastAPI(
    title="ChainCacao API",
    description="Backend API for Togo Cocoa & Coffee Traceability (Hyperledger Fabric)",
    version="2.0.0"
)

# Add Middleware
app.add_middleware(SafeEncodingMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
