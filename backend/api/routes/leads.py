from fastapi import APIRouter, HTTPException, Depends, Request, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from slowapi import Limiter
from slowapi.util import get_remote_address
from models.schemas import LeadCreateRequest, LeadCreateResponse
from database.models import Lead, Analysis
from database import get_db
from config.settings import settings
from datetime import datetime
from typing import Optional

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


async def verify_admin_api_key(x_api_key: Optional[str] = Header(None)):
    """
    Dependency to verify admin API key from X-API-Key header.
    Raises 401 if key is missing or invalid.
    """
    if not settings.admin_api_key:
        raise HTTPException(
            status_code=500,
            detail="Admin API key not configured on server"
        )

    if not x_api_key:
        raise HTTPException(
            status_code=401,
            detail="Missing X-API-Key header"
        )

    if x_api_key != settings.admin_api_key:
        raise HTTPException(
            status_code=403,
            detail="Invalid API key"
        )

    return True


@router.post("/leads", response_model=LeadCreateResponse)
@limiter.limit("5/minute")
async def create_lead(
    request_data: LeadCreateRequest,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Capture a lead from the public report page.
    Stores name, email, source URL, and share token.
    """

    # Validate share_token if provided
    if request_data.share_token:
        result = await db.execute(
            select(Analysis).where(Analysis.share_token == request_data.share_token)
        )
        analysis = result.scalar_one_or_none()
        if not analysis:
            raise HTTPException(status_code=404, detail="Invalid share token")
        analysis_id = analysis.id
    else:
        analysis_id = None

    # Create lead
    lead = Lead(
        name=request_data.name,
        email=request_data.email,
        source_url=request_data.source_url,
        share_token=request_data.share_token,
        analysis_id=analysis_id,
        user_agent=request.headers.get("user-agent"),
        ip_address=request.client.host if request.client else None,
    )

    db.add(lead)
    await db.commit()
    await db.refresh(lead)

    return LeadCreateResponse(
        id=lead.id,
        email=lead.email,
        created_at=lead.created_at,
    )


@router.get("/leads")
async def list_leads(
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 50,
    _: bool = Depends(verify_admin_api_key)
):
    """
    List all leads (admin endpoint - protected with API key authentication)
    Requires X-API-Key header with valid admin API key.
    """
    result = await db.execute(
        select(Lead).offset(skip).limit(limit).order_by(Lead.created_at.desc())
    )
    leads = result.scalars().all()

    return {
        "leads": [
            {
                "id": lead.id,
                "email": lead.email,
                "name": lead.name,
                "share_token": lead.share_token,
                "source_url": lead.source_url,
                "created_at": lead.created_at.isoformat(),
            }
            for lead in leads
        ],
        "total": len(leads),
    }
