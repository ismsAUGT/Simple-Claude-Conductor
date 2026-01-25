#!/bin/bash
# Hook: MCP-First Reminder (UserPromptSubmit)
# Reminds to use MCP tools before Grep/Glob for file discovery

# Get the prompt from stdin (Claude passes it via stdin for UserPromptSubmit hooks)
if [ -n "$CLAUDE_PROMPT" ]; then
    PROMPT="$CLAUDE_PROMPT"
else
    PROMPT=$(cat)
fi

PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
SEARCH_KEYWORDS="find|search|where|locate|look for|grep|glob|which file"

if echo "$PROMPT_LOWER" | grep -qE "$SEARCH_KEYWORDS"; then
    cat << 'EOF'
{
    "result": "continue",
    "message": "MCP-First: Before using Grep/Glob, try MCP tools for file discovery. Add found files to docs/planning/references.md."
}
EOF
else
    echo '{"result": "continue"}'
fi
