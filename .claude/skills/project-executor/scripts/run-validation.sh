#!/bin/bash
# Quick Validation Runner
# Tests simple approach before full planning
#
# Usage:
#   ./run-validation.sh check "task description"   - Check if validation should run and generate context
#   ./run-validation.sh parse "validation result"  - Parse validation output and recommend action

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source execute-plan for shared functions (suppress output)
source "$SCRIPT_DIR/execute-plan.sh" > /dev/null 2>&1 || true

# Run validation check
run_validation() {
    local task="$1"

    # Parse configs
    parse_config
    parse_validation_config

    echo "========================================"
    echo "  Quick Validation Check"
    echo "========================================"
    echo ""
    echo "Task: $task"
    echo "Validation Enabled: $VALIDATION_ENABLED"
    echo "Token Budget: $VALIDATION_MAX_TOKENS"
    echo "Max Samples: $VALIDATION_MAX_SAMPLES"
    echo "Confidence Threshold: $VALIDATION_THRESHOLD"
    echo ""

    # Check if validation is disabled
    if [ "$VALIDATION_ENABLED" = "false" ]; then
        echo "DECISION: Validation disabled in project.yaml"
        echo "RECOMMENDATION: FULL_PLANNING"
        return
    fi

    # Check skip conditions
    if [ "$(should_skip_validation "$task")" = "true" ]; then
        echo "DECISION: Skip validation (complexity keywords detected)"
        echo "RECOMMENDATION: FULL_PLANNING"
        return
    fi

    # Generate validation prompt
    echo "DECISION: Run quick validation"
    echo ""
    echo "--- Validation Context for Agent ---"
    generate_validation_context "$task"
    echo "--- End Context ---"
    echo ""
    echo "Ready for validation agent."
}

# Parse validation result and provide decision
parse_validation_result() {
    local result="$1"

    echo "========================================"
    echo "  Validation Result Parser"
    echo "========================================"
    echo ""

    # Extract confidence (look for number after "confidence:")
    local confidence=$(echo "$result" | grep -iE "confidence:" | grep -oE "[0-9]+" | head -1)

    # Extract recommendation
    local recommendation=$(echo "$result" | grep -iE "recommendation:" | sed 's/.*: *//' | tr '[:lower:]' '[:upper:]')

    # Extract blockers
    local blockers=$(echo "$result" | grep -iE "blockers:" | sed 's/.*: *//')

    echo "Parsed Values:"
    echo "  Confidence: ${confidence:-0}%"
    echo "  Recommendation: ${recommendation:-UNKNOWN}"
    echo "  Blockers: ${blockers:-none}"
    echo ""

    # Decision logic
    local threshold_percent=$(echo "$VALIDATION_THRESHOLD * 100" | bc 2>/dev/null || echo "80")

    if [ -z "$confidence" ]; then
        echo "DECISION: Could not parse confidence, proceed with FULL_PLANNING"
        return
    fi

    if [ "${confidence:-0}" -ge "${threshold_percent%.*}" ]; then
        echo "DECISION: Confidence ${confidence}% >= ${threshold_percent}% threshold"
        echo "RECOMMENDATION: SIMPLE_PLAN"
        echo ""
        echo "Suggested simplified plan:"
        echo "  Phase 1: Execute validated approach"
        echo "  Phase 2: Verify and deliver"
    else
        echo "DECISION: Confidence ${confidence}% < ${threshold_percent}% threshold"
        echo "RECOMMENDATION: FULL_PLANNING"
        echo ""
        echo "Proceed with detailed multi-phase planning."
    fi
}

# Show validation configuration
show_config() {
    parse_config
    parse_validation_config

    echo "========================================"
    echo "  Validation Configuration"
    echo "========================================"
    echo ""
    echo "validation:"
    echo "  enabled: $VALIDATION_ENABLED"
    echo "  max_tokens: $VALIDATION_MAX_TOKENS"
    echo "  max_sample_items: $VALIDATION_MAX_SAMPLES"
    echo "  confidence_threshold: $VALIDATION_THRESHOLD"
    echo "  skip_keywords: $VALIDATION_SKIP_KEYWORDS"
}

# Main command handling
case "${1:-help}" in
    check)
        run_validation "${2:-No task provided}"
        ;;
    parse)
        parse_validation_result "${2:-}"
        ;;
    config)
        show_config
        ;;
    help|*)
        echo "Quick Validation Runner"
        echo ""
        echo "Usage:"
        echo "  $0 check \"task description\"    - Check if validation should run"
        echo "  $0 parse \"validation result\"   - Parse validation output"
        echo "  $0 config                        - Show validation configuration"
        echo ""
        echo "Examples:"
        echo "  $0 check \"Rename files from .txt to .md\""
        echo "  $0 check \"Design authentication architecture\""
        echo "  $0 parse \"confidence: 85%, recommendation: SIMPLE_PLAN\""
        ;;
esac
