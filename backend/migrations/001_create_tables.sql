-- Create analyses table for shareable reports
CREATE TABLE IF NOT EXISTS analyses (
    id VARCHAR PRIMARY KEY,
    share_token VARCHAR UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Address details
    address VARCHAR NOT NULL,
    lat FLOAT NOT NULL,
    lng FLOAT NOT NULL,
    display_name VARCHAR,

    -- Score data
    overall_score FLOAT NOT NULL,
    profile VARCHAR DEFAULT 'default',
    score_data JSONB,

    -- Results
    amenities JSONB,
    ai_summary TEXT,
    amenities_count INTEGER DEFAULT 0,

    -- Metadata
    radius FLOAT DEFAULT 2000.0
);

CREATE INDEX IF NOT EXISTS idx_analyses_share_token ON analyses(share_token);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON analyses(created_at DESC);

-- Create leads table for email capture
CREATE TABLE IF NOT EXISTS leads (
    id VARCHAR PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Lead info
    name VARCHAR,
    email VARCHAR NOT NULL,

    -- Source tracking
    source_url VARCHAR,
    share_token VARCHAR,
    analysis_id VARCHAR,

    -- Additional context
    user_agent VARCHAR,
    ip_address VARCHAR
);

CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_share_token ON leads(share_token);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
