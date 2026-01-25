#!/bin/bash
# Hook: Post-Tool Handler (PostToolUse)
# Consolidated hook that runs after tool execution
#
# Actions by tool type:
# - Grep|Glob|Read|WebSearch|WebFetch: 2-Action Rule reminder
# - Edit|Write (code files): Quality gates reminder
# - Edit|Write (task-plan.md): Validation reminder
#
# Consolidates: findings-reminder.sh, quality-gates.sh, phase-completion-check.sh

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

MESSAGES=()

# Helper to extract JSON field
extract_field() {
    local field="$1"
    echo "$TOOL_INPUT" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//' || echo ""
}

# ============================================================================
# RESEARCH TOOLS: 2-Action Rule Reminder
# ============================================================================
RESEARCH_TOOLS="Grep|Glob|Read|WebSearch|WebFetch|Task"

if echo "$TOOL_NAME" | grep -qE "^($RESEARCH_TOOLS)$"; then
    # Don't remind if reading/updating planning files themselves
    if ! echo "$TOOL_INPUT" | grep -qE "docs/planning/(task-plan|findings|progress|references)\.md"; then
        MESSAGES+=("2-Action Rule: If this is your 2nd research operation, update docs/planning/findings.md with what you learned.")
    fi
fi

# ============================================================================
# CODE FILE EDITS: Quality Gates Reminder
# ============================================================================
CODE_EXTENSIONS="\.js$|\.ts$|\.tsx$|\.jsx$|\.py$|\.go$|\.rs$|\.java$|\.rb$|\.php$|\.cs$|\.cpp$|\.c$|\.swift$|\.kt$"

if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(extract_field "file_path")

    # Check if this is a code file
    if echo "$FILE_PATH" | grep -qE "$CODE_EXTENSIONS"; then
        # Check quality gate settings in project.yaml
        if [ -f "project.yaml" ]; then
            RUN_TESTS=$(grep -E "^\s+run_tests:" project.yaml 2>/dev/null | sed 's/.*: *//' | tr -d ' ' || echo "false")
            TYPECHECK=$(grep -E "^\s+typecheck:" project.yaml 2>/dev/null | sed 's/.*: *//' | tr -d ' ' || echo "false")
            LINT=$(grep -E "^\s+lint:" project.yaml 2>/dev/null | sed 's/.*: *//' | tr -d ' ' || echo "false")

            GATES_ENABLED=""
            [ "$RUN_TESTS" = "true" ] && GATES_ENABLED="${GATES_ENABLED}tests, "
            [ "$TYPECHECK" = "true" ] && GATES_ENABLED="${GATES_ENABLED}typecheck, "
            [ "$LINT" = "true" ] && GATES_ENABLED="${GATES_ENABLED}lint, "

            if [ -n "$GATES_ENABLED" ]; then
                GATES_ENABLED="${GATES_ENABLED%, }"  # Remove trailing comma
                MESSAGES+=("Quality Gates ($GATES_ENABLED): Run checks before marking phase complete.")
            fi
        fi
    fi
fi

# ============================================================================
# TASK-PLAN.MD EDITS: Validation Reminder
# ============================================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(extract_field "file_path")

    # Check if modifying task-plan.md (might be marking phase complete)
    if echo "$FILE_PATH" | grep -qE "task-plan\.md$"; then
        PROGRESS_FILE="docs/planning/progress.md"

        # Check if validation was documented
        if [ -f "$PROGRESS_FILE" ]; then
            if ! grep -q "## Validation:" "$PROGRESS_FILE" 2>/dev/null; then
                MESSAGES+=("Validation: Run output-validation skill before marking phase complete. Document results in progress.md.")
            fi
        else
            MESSAGES+=("Validation: Create progress.md and document validation before marking phase complete.")
        fi
    fi
fi

# ============================================================================
# STATUS.MD REMINDER (after any significant operation)
# ============================================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(extract_field "file_path")

    # If editing code or task-plan but NOT STATUS.md, remind to update status
    if echo "$FILE_PATH" | grep -qE "$CODE_EXTENSIONS|task-plan\.md$"; then
        if ! echo "$FILE_PATH" | grep -qE "STATUS\.md$"; then
            # Only add if we don't already have too many messages
            if [ ${#MESSAGES[@]} -lt 2 ]; then
                MESSAGES+=("Remember to update STATUS.md with current progress.")
            fi
        fi
    fi
fi

# ============================================================================
# OUTPUT
# ============================================================================
if [ ${#MESSAGES[@]} -gt 0 ]; then
    # Join messages, limit to 2 most important
    if [ ${#MESSAGES[@]} -gt 2 ]; then
        MESSAGES=("${MESSAGES[@]:0:2}")
    fi
    COMBINED_MSG=$(printf '%s ' "${MESSAGES[@]}" | sed 's/ $//')
    cat << EOF
{
    "result": "continue",
    "message": "$COMBINED_MSG"
}
EOF
else
    echo '{"result": "continue"}'
fi
