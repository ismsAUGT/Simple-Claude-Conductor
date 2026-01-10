#!/bin/bash
# Project Executor - Main Execution Script
# Reads task-plan.md and orchestrates phase execution
#
# This script provides helper functions and utilities for the Claude-driven
# execution process. The actual orchestration is done by Claude using Task agents.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load configuration
CONFIG_FILE="$PROJECT_ROOT/project.yaml"
PLANNING_DIR="$PROJECT_ROOT/docs/planning"
TASK_PLAN="$PLANNING_DIR/task-plan.md"
FINDINGS="$PLANNING_DIR/findings.md"
PROGRESS="$PLANNING_DIR/progress.md"
REFERENCES="$PLANNING_DIR/references.md"

# Default configuration
DEFAULT_MODEL="sonnet"
BYPASS_PERMISSIONS="false"
INTERRUPT_QUESTIONS="true"
MAX_AUTO_PHASES="5"

# Parse YAML config (simplified - real implementation would use yq or python)
parse_config() {
    if [ -f "$CONFIG_FILE" ]; then
        DEFAULT_MODEL=$(grep -E "^\s+default_model:" "$CONFIG_FILE" | sed 's/.*: *"//' | sed 's/".*//' || echo "sonnet")
        BYPASS_PERMISSIONS=$(grep -E "^\s+bypass_permissions:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "false")
        INTERRUPT_QUESTIONS=$(grep -E "^\s+interrupt_for_questions:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "true")
        MAX_AUTO_PHASES=$(grep -E "^\s+max_auto_phases:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "5")
    fi
}

# Check if planning files exist
check_planning_files() {
    local missing=()

    [ ! -f "$TASK_PLAN" ] && missing+=("task-plan.md")
    [ ! -f "$FINDINGS" ] && missing+=("findings.md")
    [ ! -f "$PROGRESS" ] && missing+=("progress.md")
    [ ! -f "$REFERENCES" ] && missing+=("references.md")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing planning files: ${missing[*]}"
        echo "Run: bash .claude/skills/planning-with-files/scripts/init-planning.sh"
        return 1
    fi

    return 0
}

# Extract phases from task-plan.md
extract_phases() {
    # Extract phase names and their status
    grep -E "^### Phase [0-9]+:" "$TASK_PLAN" | while read -r line; do
        phase_num=$(echo "$line" | grep -oE "Phase [0-9]+" | grep -oE "[0-9]+")
        phase_name=$(echo "$line" | sed 's/^### Phase [0-9]*: *//')
        echo "$phase_num|$phase_name"
    done
}

# Get phase status
get_phase_status() {
    local phase_num="$1"
    local status=$(grep -A3 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Status\*\*:" | sed 's/.*: *//')
    echo "${status:-Not Started}"
}

# Get phase complexity
get_phase_complexity() {
    local phase_num="$1"
    local complexity=$(grep -A4 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Complexity\*\*:" | sed 's/.*: *//')
    echo "${complexity:-Medium}"
}

# Get phase model
get_phase_model() {
    local phase_num="$1"
    local model=$(grep -A5 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Model\*\*:" | sed 's/.*: *//')
    echo "${model:-$DEFAULT_MODEL}"
}

# Determine model from complexity (if not explicitly set)
complexity_to_model() {
    local complexity="$1"
    case "$complexity" in
        Low|low)    echo "haiku" ;;
        Medium|medium) echo "sonnet" ;;
        High|high)  echo "opus" ;;
        *)          echo "$DEFAULT_MODEL" ;;
    esac
}

# Score complexity based on phase description
score_complexity() {
    local description="$1"
    local score=0

    # High complexity keywords
    for kw in architecture design complex algorithm security debug optimize; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 3))
        fi
    done

    # Medium complexity keywords
    for kw in implement build create refactor test integrate; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 2))
        fi
    done

    # Low complexity keywords
    for kw in format rename move document simple update fix; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 1))
        fi
    done

    # Return complexity level
    if [ $score -ge 6 ]; then
        echo "High"
    elif [ $score -ge 3 ]; then
        echo "Medium"
    else
        echo "Low"
    fi
}

# Find next phase to execute
find_next_phase() {
    extract_phases | while IFS='|' read -r num name; do
        status=$(get_phase_status "$num")
        if [ "$status" = "Not Started" ] || [ "$status" = "In Progress" ]; then
            echo "$num"
            return
        fi
    done
}

# Generate context injection for a phase
generate_context_injection() {
    local phase_num="$1"

    echo "## Context Injection"
    echo "You are executing Phase $phase_num"
    echo ""

    # Goal
    echo "### Project Goal"
    sed -n '/^## Goal/,/^## /p' "$TASK_PLAN" | head -n -1 | tail -n +2
    echo ""

    # Phase requirements
    echo "### Phase Requirements"
    sed -n "/^### Phase $phase_num:/,/^### Phase/p" "$TASK_PLAN" | head -n -1
    echo ""

    # Last 2 progress entries
    echo "### Previous Progress"
    grep -A20 "^### Session" "$PROGRESS" | head -40
    echo ""

    # Instructions
    cat << 'EOF'
### Your Instructions
1. Complete all deliverables listed above
2. Update docs/planning/findings.md for any research (2-Action Rule)
3. Update docs/planning/progress.md when phase is complete
4. Check off completed deliverables in task-plan.md
5. Report any blockers immediately
EOF
}

# Main execution status
show_status() {
    echo "========================================"
    echo "  Project Execution Status"
    echo "========================================"
    echo ""
    echo "Configuration:"
    echo "  Default Model: $DEFAULT_MODEL"
    echo "  Bypass Permissions: $BYPASS_PERMISSIONS"
    echo "  Interrupt for Questions: $INTERRUPT_QUESTIONS"
    echo "  Max Auto Phases: $MAX_AUTO_PHASES"
    echo ""
    echo "Phases:"
    extract_phases | while IFS='|' read -r num name; do
        status=$(get_phase_status "$num")
        complexity=$(get_phase_complexity "$num")
        model=$(get_phase_model "$num")
        printf "  Phase %s: %-30s [%s] %s/%s\n" "$num" "$name" "$status" "$complexity" "$model"
    done
    echo ""
    echo "Next phase: $(find_next_phase)"
}

# Command handling
case "${1:-status}" in
    status)
        parse_config
        check_planning_files && show_status
        ;;
    check)
        check_planning_files && echo "All planning files present."
        ;;
    context)
        parse_config
        check_planning_files && generate_context_injection "${2:-1}"
        ;;
    next)
        parse_config
        check_planning_files && find_next_phase
        ;;
    *)
        echo "Usage: $0 {status|check|context [phase_num]|next}"
        exit 1
        ;;
esac
