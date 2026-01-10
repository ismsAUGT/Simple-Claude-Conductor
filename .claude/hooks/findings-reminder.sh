#!/bin/bash
# Hook: Findings Reminder (PostToolUse)
# Reminds to update findings.md after research operations (2-Action Rule)

# Get tool name from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Research tools that should trigger the reminder
RESEARCH_TOOLS="Grep|Glob|Read|WebSearch|WebFetch|Task"

if echo "$TOOL_NAME" | grep -qE "^($RESEARCH_TOOLS)$"; then
    # Check if this looks like a research operation (not just reading planning files)
    TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

    # Don't remind if reading/updating planning files
    if echo "$TOOL_INPUT" | grep -qE "docs/planning/(task-plan|findings|progress|references)\.md"; then
        echo '{"result": "continue"}'
        exit 0
    fi

    cat << 'EOF'
{
    "result": "continue",
    "message": "2-Action Rule: If this is your 2nd research operation, update docs/planning/findings.md with what you learned."
}
EOF
else
    echo '{"result": "continue"}'
fi
