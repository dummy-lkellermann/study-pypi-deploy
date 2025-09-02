#!/bin/bash
set -euo pipefail

# setup-environment.sh
# Sets up the Python environment with all required dependencies for CI/CD
# Usage: ./setup-environment.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

main() {
    log_info "Setting up Python environment..."

    # Upgrade pip
    log_info "Upgrading pip..."
    python -m pip install --upgrade pip


    # Install build tools
    log_info "Installing build tools..."
    pip install build

    # Install test tools:
    log_info "Test tools"
    pip install pytest pytest-cov
    # Install project dependencies
    log_info "Installing project dependencies..."
    pip install -r requirements.txt

    # Install security scan tools
    log_info "Installing security scan tools..."
    pip install bandit[toml] safety ggshield

    log_info "Environment setup completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
