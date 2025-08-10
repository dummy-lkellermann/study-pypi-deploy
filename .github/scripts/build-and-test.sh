#!/bin/bash
set -euo pipefail

# build-and-test.sh
# Builds the package, installs it non-editably, and prepares for testing
# Usage: ./build-and-test.sh

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

extract_version() {
    log_info "Extracting version from pyproject.toml..."
    VERSION=$(python -c "import tomllib; f=open('pyproject.toml','rb'); data=tomllib.load(f); print(data['project']['version'])")
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"
    log_info "Version: $VERSION"
}

build_packages() {
    log_info "Building distribution packages..."
    python -m build --sdist --wheel --outdir dist/

    log_info "Built packages:"
    ls -la dist/
}

verify_packages() {
    log_info "Verifying build artifacts with twine..."
    python -m twine check dist/*
    log_info "All packages verified successfully!"
}

install_package() {
    log_info "Installing built package in non-editable mode..."
    # Install the wheel package in non-editable mode
    pip install dist/*.whl
    log_info "Package installed successfully!"
}

main() {
    log_info "Starting build and test preparation..."

    extract_version
    build_packages
    verify_packages
    install_package

    log_info "Build and test preparation completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
