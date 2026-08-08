from sqlalchemy import Column, String, DateTime, Float, Integer, JSON, Text
from sqlalchemy.sql import func
from database import Base
import uuid


def generate_uuid():
    return str(uuid.uuid4())


class Analysis(Base):
    """Stores analysis results for sharing via public URLs"""
    __tablename__ = "analyses"

    id = Column(String, primary_key=True, default=generate_uuid)
    share_token = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Address details
    address = Column(String, nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    display_name = Column(String)

    # Score data
    overall_score = Column(Float, nullable=False)
    profile = Column(String, default="default")
    score_data = Column(JSON)  # Full LocationScore as JSON

    # Results
    amenities = Column(JSON)  # List of amenities
    ai_summary = Column(Text)
    amenities_count = Column(Integer, default=0)

    # Metadata
    radius = Column(Float, default=2000.0)


class Lead(Base):
    """Stores email leads from public report pages"""
    __tablename__ = "leads"

    id = Column(String, primary_key=True, default=generate_uuid)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Lead info
    name = Column(String)
    email = Column(String, nullable=False, index=True)

    # Source tracking
    source_url = Column(String)
    share_token = Column(String, index=True)
    analysis_id = Column(String)

    # Additional context
    user_agent = Column(String)
    ip_address = Column(String)
