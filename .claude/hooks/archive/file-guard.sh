#!/bin/bash
# Hook: File Organization Guard (PreToolUse - Write)
# Warns when creating ad-hoc files in the planning directory root

# Get file path from environment or stdin
if [ -n "$CLAUDE_TOOL_INPUT" ]; then
    INPUT="$CLAUDE_TOOL_INPUT"
else
    INPUT=$(cat)
fi

# Extract file_path from JSON input
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

PLANNING_DIR="docs/planning"

# Check if creating a markdown file directly in planning root
if echo "$FILE_PATH" | grep -qE "$PLANNING_DIR/[^/]+\.md$"; then
    FILENAME=$(basename "$FILE_PATH")

    # Allowed files in planning root
    ALLOWED_FILES="README.md|task-plan.md|findings.md|progress.md|references.md|execution-summary.md"

    if ! echo "$FILENAME" | grep -qE "^($ALLOWED_FILES)$"; then
        cat << EOF
{
    "result": "continue",
    "message": "Creating '$FILENAME' in planning root. Consider: reports/ for detailed reports, archive/ for completed work."
}
EOF
        exit 0
    fi
fi

echo '{"result": "continue"}'
