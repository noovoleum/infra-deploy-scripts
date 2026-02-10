#!/bin/sh
# Check and install requirements for infra-deploy-scripts
# This script verifies that all required tools are installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

echo "=== infra-deploy-scripts Requirements Check ==="
echo ""

OS_UNAME="$(uname -s 2>/dev/null || echo unknown)"
case "$OS_UNAME" in
    MINGW*|MSYS*|CYGWIN*)
        echo -e "${RED}Windows detected. WSL is required for infra-deploy-scripts.${NC}"
        echo "Install WSL (PowerShell as Administrator):"
        echo "  wsl --install"
        echo "Docs: https://learn.microsoft.com/windows/wsl/install"
        exit 1
        ;;
esac

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check a requirement
check_requirement() {
    local name="$1"
    local command="$2"
    local install_cmd="$3"
    local required="${4:-true}"

    printf "%-30s " "$name"

    if command_exists "$command"; then
        local version
        version=$(eval "$command --version 2>/dev/null | head -1" || echo "installed")
        echo -e "${GREEN}✓${NC} $version"
        PASS=$((PASS + 1))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} Not found"
            echo -e "  ${YELLOW}Install:${NC} $install_cmd"
            FAIL=$((FAIL + 1))
            return 1
        else
            echo -e "${YELLOW}⚠${NC} Not found (optional)"
            echo -e "  ${BLUE}Install:${NC} $install_cmd"
            WARN=$((WARN + 1))
            return 0
        fi
    fi
}

# Check requirements
echo "Checking required tools..."
echo ""

check_requirement "Git" "git" "https://git-scm.com/downloads" "true"
check_requirement "OpenSSL" "openssl" \
    "Ubuntu/Debian: sudo apt install openssl
     macOS: brew install openssl
     Arch: sudo pacman -S openssl" \
    "true"

check_requirement "just (command runner)" "just" \
    "cargo install just
     OR: brew install just (macOS)
     OR: sudo pacman -S just (Arch)" \
    "false"

check_requirement "base64" "base64" "Usually pre-installed" "true"
check_requirement "tr" "tr" "Usually pre-installed" "true"
check_requirement "grep" "grep" "Usually pre-installed" "true"

echo ""
echo "=== Summary ==="
echo -e "${GREEN}Passed:${NC} $PASS"
if [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC} $WARN"
fi
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Failed:${NC} $FAIL"
    echo ""
    echo -e "${RED}Some required tools are missing. Please install them and run this script again.${NC}"
    exit 1
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All required tools are installed!${NC}"
    if [ $WARN -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Note: Some optional tools are not installed.${NC}"
        echo "The setup will work without them, but you may want to install them for better functionality."
    fi
    echo ""
    echo "You can now run: ./scripts/setup.sh"
    exit 0
fi
