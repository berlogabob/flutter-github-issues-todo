#!/bin/bash

# GitDoIt - Run with OAuth Configuration
# This script reads GITHUB_CLIENT_ID from .env file

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitDoIt - Starting...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo ""
    echo "Please create .env file:"
    echo "  cp .env.example .env"
    echo ""
    echo "Then edit .env and add your GitHub OAuth Client ID:"
    echo "  GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx"
    echo ""
    echo "Get your Client ID from:"
    echo "  https://github.com/settings/developers"
    echo ""
    exit 1
fi

# Read GITHUB_CLIENT_ID from .env
GITHUB_CLIENT_ID=$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2 | tr -d '[:space:]')

# Validate Client ID
if [ -z "$GITHUB_CLIENT_ID" ] || [ "$GITHUB_CLIENT_ID" = "your_client_id_here" ]; then
    echo -e "${RED}Error: GITHUB_CLIENT_ID is not set in .env file!${NC}"
    echo ""
    echo "Please edit .env and set your GitHub OAuth Client ID:"
    echo "  GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx"
    echo ""
    echo "Get your Client ID from:"
    echo "  https://github.com/settings/developers"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Found GITHUB_CLIENT_ID: ${GITHUB_CLIENT_ID:0:8}...${NC}"
echo ""

# Run the app
echo -e "${YELLOW}Starting Flutter app...${NC}"
flutter run --dart-define=GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID"
