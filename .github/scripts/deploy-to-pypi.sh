#!/bin/bash
set -euo pipefail

# deploy-to-pypi.sh
# Deploys packages to PyPI (test or production)
# Usage: ./deploy-to-pypi.sh <target> <version>
# Where target is either "test" or "production"

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

verify_artifacts() {
    log_info "Verifying deployment artifacts..."

    if [ ! -d "dist" ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
        log_error "No distribution files found in dist/ directory"
        exit 1
    fi

    ls -la dist/
    python -m twine check dist/*

    log_info "All artifacts verified successfully!"
}

deploy_to_test_pypi() {
    local version="$1"

    log_info "Deploying version $version to Test PyPI..."

    if [[ -z "${TEST_PYPI_API_TOKEN:-}" ]]; then
        log_error "TEST_PYPI_API_TOKEN environment variable is not set"
        exit 1
    fi

    export TWINE_USERNAME="__token__"
    export TWINE_PASSWORD="$TEST_PYPI_API_TOKEN"

    python -m twine upload dist/* --verbose

    log_info "✅ Successfully deployed v$version to test.pypi.org"
    echo "Git tag was already created during CI stage"
}

deploy_to_production_pypi() {
    local version="$1"

    log_info "Deploying version $version to Production PyPI..."

    if [[ -z "${PYPI_API_TOKEN:-}" ]]; then
        log_error "PYPI_API_TOKEN environment variable is not set"
        exit 1
    fi

    export TWINE_USERNAME="__token__"
    export TWINE_PASSWORD="$PYPI_API_TOKEN"

    python -m twine upload dist/* --verbose

    log_info "✅ Successfully deployed v$version to pypi.org"
}

validate_production_tag() {
    local version="$1"

    log_info "Validating that git tag exists for production deployment..."

    TAG="v$version"
    if ! git tag -l "$TAG" | grep -q "$TAG"; then
        log_error "Tag $TAG does not exist. Deploy to test-pypi first to create the tag."
        exit 1
    fi

    log_info "✅ Tag $TAG exists"
}

main() {
    local target="${1:-}"
    local version="${2:-}"

    if [[ -z "$target" ]] || [[ -z "$version" ]]; then
        log_error "Both target and version parameters are required"
        echo "Usage: $0 <target> <version>"
        echo "  target: 'test' or 'production'"
        echo "  version: package version (e.g., '1.0.0')"
        exit 1
    fi

    # Install deployment dependencies
    log_info "Installing deployment dependencies..."
    python -m pip install --upgrade pip twine

    verify_artifacts

    case "$target" in
        "test")
            deploy_to_test_pypi "$version"
            ;;
        "production")
            validate_production_tag "$version"
            deploy_to_production_pypi "$version"
            ;;
        *)
            log_error "Invalid target: $target. Must be 'test' or 'production'"
            exit 1
            ;;
    esac

    log_info "Deployment completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
