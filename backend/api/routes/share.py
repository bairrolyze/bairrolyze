import secrets
from fastapi import APIRouter, HTTPException, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from slowapi import Limiter
from slowapi.util import get_remote_address
from models.schemas import AnalyzeResponse, ShareAnalysisResponse
from database.models import Analysis
from database import get_db

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


def generate_share_token(length: int = 12) -> str:
    """Generate a URL-safe random token"""
    return secrets.token_urlsafe(length)


@router.post("/share", response_model=ShareAnalysisResponse)
@limiter.limit("20/minute")
async def create_share(
    analysis: AnalyzeResponse,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Save an analysis result and generate a shareable link.
    Called after analyzing an address to create a public report.
    """
    share_token = generate_share_token()

    # Create database record
    db_analysis = Analysis(
        share_token=share_token,
        address=analysis.address.display_name,
        lat=analysis.address.lat,
        lng=analysis.address.lng,
        display_name=analysis.address.display_name,
        overall_score=analysis.score.overall,
        profile=analysis.profile,
        score_data=analysis.score.model_dump(mode='json'),
        amenities=[a.model_dump(mode='json') for a in analysis.amenities],
        ai_summary=analysis.ai_summary,
        amenities_count=len(analysis.amenities),
        radius=2000.0,  # Default from analyze request
    )

    db.add(db_analysis)
    await db.commit()
    await db.refresh(db_analysis)

    # Generate share URL (frontend will handle /r/{token})
    share_url = f"/r/{share_token}"

    return ShareAnalysisResponse(
        share_token=share_token,
        share_url=share_url,
        analysis_id=db_analysis.id,
    )


@router.get("/share/{token}")
async def get_shared_analysis(
    token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve a shared analysis by token.
    Used by the public report page to display results.
    """
    result = await db.execute(
        select(Analysis).where(Analysis.share_token == token)
    )
    analysis = result.scalar_one_or_none()

    if not analysis:
        raise HTTPException(status_code=404, detail="Report not found")

    return {
        "id": analysis.id,
        "share_token": analysis.share_token,
        "created_at": analysis.created_at.isoformat(),
        "address": {
            "display_name": analysis.display_name,
            "lat": analysis.lat,
            "lng": analysis.lng,
        },
        "overall_score": analysis.overall_score,
        "profile": analysis.profile,
        "score_data": analysis.score_data,
        "amenities": analysis.amenities,
        "ai_summary": analysis.ai_summary,
        "amenities_count": analysis.amenities_count,
    }
