#!/bin/bash
# Quick Iteration Runner
# Self-checks outputs and fixes errors before final delivery
#
# Usage:
#   ./run-iteration.sh check "task" "outputs"  - Check if iteration should run and generate context
#   ./run-iteration.sh parse "iteration result" - Parse iteration output and recommend action
#   ./run-iteration.sh config                   - Show iteration configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source execute-plan for shared functions (suppress output)
source "$SCRIPT_DIR/execute-plan.sh" > /dev/null 2>&1 || true

# Run iteration check
run_iteration() {
    local task="$1"
    local outputs="$2"

    # Parse configs
    parse_config
    parse_iteration_config

    echo "========================================"
    echo "  Quick Iteration Check"
    echo "========================================"
    echo ""
    echo "Task: $task"
    echo "Iteration Enabled: $ITERATION_ENABLED"
    echo "Token Budget: $ITERATION_MAX_TOKENS"
    echo "Sample Size: $ITERATION_SAMPLE_SIZE"
    echo "Error Threshold: $ITERATION_ERROR_THRESHOLD"
    echo "Max Iterations: $ITERATION_MAX_ITERATIONS"
    echo ""

    # Check if iteration is disabled
    if [ "$ITERATION_ENABLED" = "false" ]; then
        echo "DECISION: Iteration disabled in project.yaml"
        echo "RECOMMENDATION: DELIVER"
        return
    fi

    # Check skip conditions
    if [ "$(should_skip_iteration "$task")" = "true" ]; then
        echo "DECISION: Skip iteration (task type keywords detected)"
        echo "RECOMMENDATION: DELIVER"
        return
    fi

    # Generate iteration prompt
    echo "DECISION: Run quick iteration"
    echo ""
    echo "--- Iteration Context for Agent ---"
    generate_iteration_context "$task" "$outputs"
    echo "--- End Context ---"
    echo ""
    echo "Ready for iteration agent."
}

# Parse iteration result and provide decision
parse_iteration_result() {
    local result="$1"

    echo "========================================"
    echo "  Iteration Result Parser"
    echo "========================================"
    echo ""

    # Extract sample size
    local sample_size=$(echo "$result" | grep -iE "sample_size:" | grep -oE "[0-9]+" | head -1)

    # Extract errors found
    local errors_found=$(echo "$result" | grep -iE "errors_found:" | grep -oE "[0-9]+" | head -1)

    # Extract error rate (look for number before %)
    local error_rate=$(echo "$result" | grep -iE "error_rate:" | grep -oE "[0-9]+\.?[0-9]*" | head -1)

    # Extract recommendation
    local recommendation=$(echo "$result" | grep -iE "recommendation:" | sed 's/.*: *//' | tr '[:lower:]' '[:upper:]')

    # Extract error patterns
    local error_patterns=$(echo "$result" | grep -iE "error_patterns:" | sed 's/.*: *//')

    echo "Parsed Values:"
    echo "  Sample Size: ${sample_size:-unknown}"
    echo "  Errors Found: ${errors_found:-0}"
    echo "  Error Rate: ${error_rate:-0}%"
    echo "  Recommendation: ${recommendation:-UNKNOWN}"
    echo "  Error Patterns: ${error_patterns:-none}"
    echo ""

    # Decision logic
    local threshold_percent=$(echo "$ITERATION_ERROR_THRESHOLD * 100" | bc 2>/dev/null || echo "10")

    if [ -z "$error_rate" ]; then
        echo "DECISION: Could not parse error rate, proceeding to DELIVER"
        return
    fi

    # Compare error rate to threshold (integer comparison)
    local error_int=${error_rate%.*}
    local threshold_int=${threshold_percent%.*}

    if [ "${error_int:-0}" -le "${threshold_int:-10}" ]; then
        echo "DECISION: Error rate ${error_rate}% <= ${threshold_percent}% threshold"
        echo "RECOMMENDATION: DELIVER"
        echo ""
        echo "Output quality acceptable. Proceed to final delivery."
    else
        echo "DECISION: Error rate ${error_rate}% > ${threshold_percent}% threshold"
        echo "RECOMMENDATION: FIX_AND_DELIVER"
        echo ""
        echo "Running focused correction pass (budget: $ITERATION_MAX_TOKENS tokens)"
        echo "Focus on fixing: ${error_patterns:-identified errors}"
        echo ""
        echo "After correction, DELIVER regardless of remaining errors."
        echo "(Max iterations: $ITERATION_MAX_ITERATIONS - no spiraling)"
    fi
}

# Show iteration configuration
show_config() {
    parse_config
    parse_iteration_config

    echo "========================================"
    echo "  Iteration Configuration"
    echo "========================================"
    echo ""
    echo "iteration:"
    echo "  enabled: $ITERATION_ENABLED"
    echo "  max_tokens: $ITERATION_MAX_TOKENS"
    echo "  sample_size: $ITERATION_SAMPLE_SIZE"
    echo "  error_threshold: $ITERATION_ERROR_THRESHOLD"
    echo "  max_iterations: $ITERATION_MAX_ITERATIONS"
    echo "  skip_keywords: $ITERATION_SKIP_KEYWORDS"
}

# Main command handling
case "${1:-help}" in
    check)
        run_iteration "${2:-No task provided}" "${3:-No outputs specified}"
        ;;
    parse)
        parse_iteration_result "${2:-}"
        ;;
    config)
        show_config
        ;;
    help|*)
        echo "Quick Iteration Runner"
        echo ""
        echo "Usage:"
        echo "  $0 check \"task\" \"outputs\"     - Check if iteration should run"
        echo "  $0 parse \"iteration result\"   - Parse iteration output"
        echo "  $0 config                       - Show iteration configuration"
        echo ""
        echo "Examples:"
        echo "  $0 check \"Map database fields\" \"31 field mappings in output/\""
        echo "  $0 check \"Create quick prototype\" \"prototype files\""
        echo "  $0 parse \"sample_size: 10, errors_found: 2, error_rate: 20%, recommendation: FIX_AND_DELIVER\""
        echo ""
        echo "Key Principles:"
        echo "  - Budget-capped: Hard limit on tokens to prevent cost spiral"
        echo "  - Self-directed: No human hints, just self-review"
        echo "  - Sample-based: Spot-check, don't re-check everything"
        echo "  - One shot: Max 1 iteration, then deliver"
        ;;
esac
