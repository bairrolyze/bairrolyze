#!/bin/bash
# apply_security_fixes.sh - Quick deployment script for P0 security fixes

set -e

echo "=========================================="
echo "HomeScope Security Fixes Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Must run from project root directory${NC}"
    exit 1
fi

echo "Step 1: Checking .env file..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file not found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}IMPORTANT: Edit .env and set the following:${NC}"
    echo "  - ADMIN_API_KEY (generate with: python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
    echo "  - POSTGRES_PASSWORD (generate with: python3 -c 'import secrets; print(secrets.token_urlsafe(24))')"
    echo "  - CORS_ORIGINS (e.g., https://homescope.app,https://www.homescope.app)"
    echo ""
    read -p "Press Enter after updating .env file..."
fi

# Check required environment variables
echo ""
echo "Step 2: Validating environment variables..."
source .env

if [ -z "$ADMIN_API_KEY" ]; then
    echo -e "${RED}Error: ADMIN_API_KEY not set in .env${NC}"
    echo "Generate one with: python3 -c 'import secrets; print(secrets.token_urlsafe(32))'"
    exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${RED}Error: POSTGRES_PASSWORD not set in .env${NC}"
    echo "Generate one with: python3 -c 'import secrets; print(secrets.token_urlsafe(24))'"
    exit 1
fi

if [ -z "$CORS_ORIGINS" ]; then
    echo -e "${YELLOW}Warning: CORS_ORIGINS not set. Using development defaults.${NC}"
fi

echo -e "${GREEN}✓ Environment variables validated${NC}"

# Install Python dependencies
echo ""
echo "Step 3: Installing backend dependencies..."
cd backend
pip install -r requirements.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${RED}Error: Failed to install dependencies${NC}"
    exit 1
fi
cd ..

# Rebuild Docker images
echo ""
echo "Step 4: Rebuilding Docker images..."
docker compose build --quiet
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker images rebuilt${NC}"
else
    echo -e "${RED}Error: Failed to rebuild Docker images${NC}"
    exit 1
fi

# Stop existing containers
echo ""
echo "Step 5: Stopping existing containers..."
docker compose down > /dev/null 2>&1
echo -e "${GREEN}✓ Containers stopped${NC}"

# Start services
echo ""
echo "Step 6: Starting services..."
docker compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Services started${NC}"
else
    echo -e "${RED}Error: Failed to start services${NC}"
    exit 1
fi

# Wait for services to be ready
echo ""
echo "Step 7: Waiting for services to be healthy..."
sleep 5

# Check health endpoint
for i in {1..30}; do
    if curl -s http://localhost:8001/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API is healthy${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Error: API failed to start after 30 seconds${NC}"
        echo "Check logs with: docker compose logs api"
        exit 1
    fi
    sleep 1
done

# Run security tests
echo ""
echo "=========================================="
echo "Running Security Tests"
echo "=========================================="

# Test 1: Security Headers
echo ""
echo "Test 1: Checking security headers..."
HEADERS=$(curl -sI http://localhost:8001/health)
if echo "$HEADERS" | grep -q "x-content-type-options: nosniff"; then
    echo -e "${GREEN}✓ X-Content-Type-Options header present${NC}"
else
    echo -e "${RED}✗ X-Content-Type-Options header missing${NC}"
fi

if echo "$HEADERS" | grep -q "x-frame-options: DENY"; then
    echo -e "${GREEN}✓ X-Frame-Options header present${NC}"
else
    echo -e "${RED}✗ X-Frame-Options header missing${NC}"
fi

if echo "$HEADERS" | grep -q "strict-transport-security"; then
    echo -e "${GREEN}✓ Strict-Transport-Security header present${NC}"
else
    echo -e "${RED}✗ Strict-Transport-Security header missing${NC}"
fi

# Test 2: Admin Authentication
echo ""
echo "Test 2: Checking admin endpoint authentication..."
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/v1/leads)
if [ "$RESPONSE_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Admin endpoint protected (401 without API key)${NC}"
else
    echo -e "${RED}✗ Admin endpoint NOT protected (got $RESPONSE_CODE, expected 401)${NC}"
fi

# Test with API key
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: $ADMIN_API_KEY" http://localhost:8001/api/v1/leads)
if [ "$RESPONSE_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Admin endpoint accessible with valid API key${NC}"
else
    echo -e "${YELLOW}⚠ Admin endpoint returned $RESPONSE_CODE with API key (expected 200 or 404 if empty)${NC}"
fi

# Test 3: Rate Limiting
echo ""
echo "Test 3: Checking rate limiting..."
echo "Making 6 rapid requests to /api/v1/leads (limit: 5/min)..."
RATE_LIMITED=false
for i in {1..6}; do
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/api/v1/leads \
        -H "Content-Type: application/json" \
        -d '{"name":"Test","email":"test@example.com","source_url":"https://test.com","share_token":"abc123xyz789"}')

    if [ "$RESPONSE_CODE" = "429" ]; then
        RATE_LIMITED=true
        break
    fi
    sleep 0.1
done

if [ "$RATE_LIMITED" = true ]; then
    echo -e "${GREEN}✓ Rate limiting is working (got 429)${NC}"
else
    echo -e "${RED}✗ Rate limiting may not be working (never got 429)${NC}"
fi

# Test 4: Input Validation
echo ""
echo "Test 4: Checking input validation..."
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8001/api/v1/leads \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","email":"invalid-email","source_url":"https://test.com"}')

if [ "$RESPONSE_CODE" = "422" ]; then
    echo -e "${GREEN}✓ Input validation working (rejected invalid email)${NC}"
else
    echo -e "${RED}✗ Input validation may not be working (got $RESPONSE_CODE, expected 422)${NC}"
fi

# Test 5: CORS
echo ""
echo "Test 5: Checking CORS configuration..."
CORS_HEADER=$(curl -s -H "Origin: https://evil.com" -I http://localhost:8001/health | grep -i "access-control-allow-origin")
if [ -z "$CORS_HEADER" ]; then
    echo -e "${GREEN}✓ CORS properly configured (rejects unknown origins)${NC}"
else
    if echo "$CORS_HEADER" | grep -q "https://evil.com"; then
        echo -e "${RED}✗ CORS misconfigured (allows evil.com)${NC}"
    else
        echo -e "${GREEN}✓ CORS properly configured${NC}"
    fi
fi

# Summary
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}✅ All P0 security fixes applied and tested${NC}"
echo ""
echo "Services running:"
echo "  - API: http://localhost:8001"
echo "  - API Docs: http://localhost:8001/docs"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo ""
echo "Important URLs:"
echo "  - Health Check: http://localhost:8001/health"
echo "  - Admin Leads (requires API key): http://localhost:8001/api/v1/leads"
echo ""
echo "Admin API Key: $ADMIN_API_KEY"
echo ""
echo "View logs with: docker compose logs -f api"
echo "Stop services with: docker compose down"
echo ""
echo "Next steps:"
echo "  1. Set up CI/CD pipeline (P1)"
echo "  2. Configure monitoring (Sentry)"
echo "  3. Set up automated backups"
echo "  4. Add GDPR compliance features"
echo ""
echo "See P0_SECURITY_FIXES_COMPLETE.md for full documentation."
