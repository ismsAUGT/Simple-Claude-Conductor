#!/bin/bash
# Hook: Pre-Tool Guard (PreToolUse)
# Consolidated hook that runs before tool execution
#
# Actions by tool type:
# - Bash: Branch protection (block dangerous git ops)
# - Write: File organization guard (warn on ad-hoc planning files)
# - Edit|Write to task-plan.md: Domain understanding check
#
# Consolidates: branch-protection.sh, file-guard.sh, pre-planning-check.sh

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Get tool input from environment or stdin
if [ -n "${CLAUDE_TOOL_INPUT:-}" ]; then
    INPUT="$CLAUDE_TOOL_INPUT"
else
    INPUT=$(cat)
fi

# Helper to extract JSON field
extract_field() {
    local field="$1"
    echo "$INPUT" | grep -o "\"$field\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$field\"[[:space:]]*:[[:space:]]*\"//" | sed 's/"$//' || echo ""
}

# ============================================================================
# BASH TOOL: Branch Protection
# ============================================================================
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(extract_field "command")

    # Block force push to main/master
    if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force.*\s+(main|master)|git\s+push\s+.*\s+(main|master).*--force"; then
        cat << 'EOF'
{
    "result": "block",
    "message": "BLOCKED: Force push to main/master. Use a feature branch instead."
}
EOF
        exit 0
    fi

    # Block hard reset to main/master
    if echo "$COMMAND" | grep -qE "git\s+reset\s+--hard\s+(origin/)?(main|master)"; then
        cat << 'EOF'
{
    "result": "block",
    "message": "BLOCKED: Hard reset to main/master would discard all local changes."
}
EOF
        exit 0
    fi

    # Warn on any force push
    if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force"; then
        cat << 'EOF'
{
    "result": "continue",
    "message": "WARNING: Force push detected. Ensure this branch is not shared."
}
EOF
        exit 0
    fi

    # Warn on any hard reset
    if echo "$COMMAND" | grep -qE "git\s+reset\s+--hard"; then
        cat << 'EOF'
{
    "result": "continue",
    "message": "WARNING: Hard reset will discard uncommitted changes."
}
EOF
        exit 0
    fi
fi

# ============================================================================
# WRITE TOOL: File Organization Guard
# ============================================================================
if [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(extract_field "file_path")
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
fi

# ============================================================================
# EDIT|WRITE to task-plan.md: Domain Understanding Check
# ============================================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(extract_field "file_path")

    # Only check when modifying task-plan.md (about to add phases)
    if echo "$FILE_PATH" | grep -qE "task-plan\.md$"; then
        FINDINGS_FILE="docs/planning/findings.md"

        # Check if findings.md exists with Domain Understanding section
        if [ ! -f "$FINDINGS_FILE" ]; then
            cat << 'EOF'
{
    "result": "continue",
    "message": "REMINDER: Run prompt-understanding skill before planning. findings.md does not exist."
}
EOF
            exit 0
        fi

        if ! grep -q "## Domain Understanding" "$FINDINGS_FILE" 2>/dev/null; then
            cat << 'EOF'
{
    "result": "continue",
    "message": "REMINDER: Run prompt-understanding skill. findings.md is missing 'Domain Understanding' section."
}
EOF
            exit 0
        fi

        # Check if section has content
        CONTENT=$(sed -n '/## Domain Understanding/,/^## /p' "$FINDINGS_FILE" 2>/dev/null | grep -v "^#" | grep -v "^$" | head -5 || echo "")
        if [ -z "$CONTENT" ]; then
            cat << 'EOF'
{
    "result": "continue",
    "message": "REMINDER: The 'Domain Understanding' section in findings.md is empty. Fill it before planning."
}
EOF
            exit 0
        fi
    fi
fi

# Default: continue without message
echo '{"result": "continue"}'
