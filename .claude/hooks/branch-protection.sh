#!/bin/bash
# Hook: Branch Protection (PreToolUse - Bash)
# Prevents dangerous git operations like force push to main/master

# The tool input is passed via environment variable or stdin
if [ -n "$CLAUDE_TOOL_INPUT" ]; then
    COMMAND="$CLAUDE_TOOL_INPUT"
else
    # Read from stdin and extract command from JSON
    INPUT=$(cat)
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
fi

# Block force push to main/master
if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force.*\s+(main|master)|git\s+push\s+.*\s+(main|master).*--force"; then
    cat << 'EOF'
{
    "result": "block",
    "message": "Force push to main/master is blocked for safety. Use a feature branch instead."
}
EOF
    exit 0
fi

# Block hard reset
if echo "$COMMAND" | grep -qE "git\s+reset\s+--hard\s+(origin/)?(main|master)"; then
    cat << 'EOF'
{
    "result": "block",
    "message": "Hard reset to main/master is blocked. This would discard all local changes."
}
EOF
    exit 0
fi

# Warn on any force push
if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force"; then
    cat << 'EOF'
{
    "result": "continue",
    "message": "Force push detected. Make sure this is intentional and the branch is not shared."
}
EOF
    exit 0
fi

# Warn on any hard reset
if echo "$COMMAND" | grep -qE "git\s+reset\s+--hard"; then
    cat << 'EOF'
{
    "result": "continue",
    "message": "Hard reset detected. This will discard uncommitted changes. Proceed with caution."
}
EOF
    exit 0
fi

echo '{"result": "continue"}'
