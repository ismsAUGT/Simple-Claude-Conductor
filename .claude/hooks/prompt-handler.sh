#!/bin/bash
# Hook: Prompt Handler (UserPromptSubmit)
# Consolidated hook that runs on every user prompt
#
# Actions:
# 1. MCP-first reminder (if search keywords detected)
# 2. Re-read task-plan.md summary to stay aligned with goals
#
# Inspired by planning-with-files PreToolUse pattern

set -euo pipefail

# Get the prompt from environment or stdin
if [ -n "${CLAUDE_PROMPT:-}" ]; then
    PROMPT="$CLAUDE_PROMPT"
else
    PROMPT=$(cat)
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
MESSAGES=()

# --- Action 1: MCP-First Reminder ---
SEARCH_KEYWORDS="find|search|where|locate|look for|grep|glob|which file"
if echo "$PROMPT_LOWER" | grep -qE "$SEARCH_KEYWORDS"; then
    MESSAGES+=("MCP-First: Before using Grep/Glob, try MCP tools for file discovery. Add found files to docs/planning/references.md.")
fi

# --- Action 2: Plan Re-Read Reminder ---
# If this looks like a major decision or implementation prompt, remind to check the plan
DECISION_KEYWORDS="implement|build|create|design|refactor|change|update|fix|add|remove|delete|modify"
PLAN_FILE="docs/planning/task-plan.md"

if echo "$PROMPT_LOWER" | grep -qE "$DECISION_KEYWORDS"; then
    if [ -f "$PLAN_FILE" ]; then
        # Check if we have phases defined
        if grep -q "^### Phase" "$PLAN_FILE" 2>/dev/null; then
            # Extract current phase status
            CURRENT_PHASE=$(grep -E "^### Phase.*\[" "$PLAN_FILE" | grep -v "Complete" | head -1 | sed 's/^### //' || echo "")
            if [ -n "$CURRENT_PHASE" ]; then
                MESSAGES+=("Current focus: $CURRENT_PHASE - Re-read task-plan.md if unsure about requirements.")
            fi
        fi
    fi
fi

# --- Output ---
if [ ${#MESSAGES[@]} -gt 0 ]; then
    # Join messages with newline
    COMBINED_MSG=$(printf '%s\n' "${MESSAGES[@]}" | tr '\n' ' ' | sed 's/ $//')
    cat << EOF
{
    "result": "continue",
    "message": "$COMBINED_MSG"
}
EOF
else
    echo '{"result": "continue"}'
fi
