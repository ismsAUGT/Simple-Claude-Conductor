#!/bin/bash
# Quality Gates Runner
# Auto-detects project type and runs appropriate quality checks
#
# Usage: ./run-quality-gates.sh [tests|typecheck|lint|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
TESTS_PASSED=true
TYPECHECK_PASSED=true
LINT_PASSED=true

# Detect project type and available tools
detect_project() {
    if [ -f "package.json" ]; then
        echo "node"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        echo "java"
    else
        echo "unknown"
    fi
}

# Run tests based on project type
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"

    PROJECT_TYPE=$(detect_project)

    case "$PROJECT_TYPE" in
        node)
            if [ -f "package.json" ]; then
                if grep -q '"test"' package.json; then
                    npm test || { TESTS_PASSED=false; return 1; }
                else
                    echo "No test script found in package.json"
                    return 0
                fi
            fi
            ;;
        python)
            if command -v pytest &> /dev/null; then
                pytest || { TESTS_PASSED=false; return 1; }
            elif command -v python &> /dev/null; then
                python -m pytest 2>/dev/null || python -m unittest discover || { TESTS_PASSED=false; return 1; }
            fi
            ;;
        go)
            go test ./... || { TESTS_PASSED=false; return 1; }
            ;;
        rust)
            cargo test || { TESTS_PASSED=false; return 1; }
            ;;
        java)
            if [ -f "pom.xml" ]; then
                mvn test || { TESTS_PASSED=false; return 1; }
            elif [ -f "build.gradle" ]; then
                ./gradlew test || { TESTS_PASSED=false; return 1; }
            fi
            ;;
        *)
            echo "Unknown project type - cannot auto-detect test command"
            return 0
            ;;
    esac

    echo -e "${GREEN}Tests passed!${NC}"
}

# Run type checking based on project type
run_typecheck() {
    echo -e "${YELLOW}Running type checks...${NC}"

    PROJECT_TYPE=$(detect_project)

    case "$PROJECT_TYPE" in
        node)
            if [ -f "tsconfig.json" ]; then
                npx tsc --noEmit || { TYPECHECK_PASSED=false; return 1; }
            else
                echo "No tsconfig.json found - skipping TypeScript check"
                return 0
            fi
            ;;
        python)
            if command -v mypy &> /dev/null; then
                mypy . || { TYPECHECK_PASSED=false; return 1; }
            elif command -v pyright &> /dev/null; then
                pyright || { TYPECHECK_PASSED=false; return 1; }
            else
                echo "No type checker found (mypy/pyright) - skipping"
                return 0
            fi
            ;;
        go)
            # Go has built-in type checking via build
            go build ./... || { TYPECHECK_PASSED=false; return 1; }
            ;;
        rust)
            cargo check || { TYPECHECK_PASSED=false; return 1; }
            ;;
        *)
            echo "Unknown project type - cannot auto-detect type checker"
            return 0
            ;;
    esac

    echo -e "${GREEN}Type check passed!${NC}"
}

# Run linter based on project type
run_lint() {
    echo -e "${YELLOW}Running linter...${NC}"

    PROJECT_TYPE=$(detect_project)

    case "$PROJECT_TYPE" in
        node)
            if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
                npx eslint . || { LINT_PASSED=false; return 1; }
            elif [ -f "biome.json" ]; then
                npx biome check . || { LINT_PASSED=false; return 1; }
            else
                echo "No linter config found - skipping"
                return 0
            fi
            ;;
        python)
            if command -v ruff &> /dev/null; then
                ruff check . || { LINT_PASSED=false; return 1; }
            elif command -v flake8 &> /dev/null; then
                flake8 . || { LINT_PASSED=false; return 1; }
            elif command -v pylint &> /dev/null; then
                pylint **/*.py || { LINT_PASSED=false; return 1; }
            else
                echo "No linter found (ruff/flake8/pylint) - skipping"
                return 0
            fi
            ;;
        go)
            if command -v golangci-lint &> /dev/null; then
                golangci-lint run || { LINT_PASSED=false; return 1; }
            else
                go vet ./... || { LINT_PASSED=false; return 1; }
            fi
            ;;
        rust)
            cargo clippy || { LINT_PASSED=false; return 1; }
            ;;
        *)
            echo "Unknown project type - cannot auto-detect linter"
            return 0
            ;;
    esac

    echo -e "${GREEN}Lint passed!${NC}"
}

# Show summary
show_summary() {
    echo ""
    echo "========================================"
    echo "  Quality Gates Summary"
    echo "========================================"

    if [ "$1" = "all" ] || [ "$1" = "tests" ]; then
        if [ "$TESTS_PASSED" = true ]; then
            echo -e "  Tests:     ${GREEN}PASSED${NC}"
        else
            echo -e "  Tests:     ${RED}FAILED${NC}"
        fi
    fi

    if [ "$1" = "all" ] || [ "$1" = "typecheck" ]; then
        if [ "$TYPECHECK_PASSED" = true ]; then
            echo -e "  Typecheck: ${GREEN}PASSED${NC}"
        else
            echo -e "  Typecheck: ${RED}FAILED${NC}"
        fi
    fi

    if [ "$1" = "all" ] || [ "$1" = "lint" ]; then
        if [ "$LINT_PASSED" = true ]; then
            echo -e "  Lint:      ${GREEN}PASSED${NC}"
        else
            echo -e "  Lint:      ${RED}FAILED${NC}"
        fi
    fi

    echo "========================================"

    # Return overall status
    if [ "$TESTS_PASSED" = true ] && [ "$TYPECHECK_PASSED" = true ] && [ "$LINT_PASSED" = true ]; then
        echo -e "${GREEN}All quality gates passed!${NC}"
        return 0
    else
        echo -e "${RED}Some quality gates failed.${NC}"
        return 1
    fi
}

# Main
case "${1:-all}" in
    tests)
        run_tests
        show_summary "tests"
        ;;
    typecheck)
        run_typecheck
        show_summary "typecheck"
        ;;
    lint)
        run_lint
        show_summary "lint"
        ;;
    all)
        run_tests || true
        run_typecheck || true
        run_lint || true
        show_summary "all"
        ;;
    detect)
        echo "Detected project type: $(detect_project)"
        ;;
    *)
        echo "Usage: $0 {tests|typecheck|lint|all|detect}"
        exit 1
        ;;
esac
