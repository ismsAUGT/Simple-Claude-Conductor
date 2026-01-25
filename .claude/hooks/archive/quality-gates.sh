#!/bin/bash
# Hook: Quality Gates (PostToolUse - Edit/Write)
# Reminds to run quality checks after code changes
# Actual validation is performed by Claude, not this hook

# This hook provides guidance - Claude handles the actual execution
# because test/lint commands vary by project and need intelligent handling

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only trigger on code file modifications
CODE_EXTENSIONS="\.js$|\.ts$|\.tsx$|\.jsx$|\.py$|\.go$|\.rs$|\.java$|\.rb$|\.php$|\.cs$|\.cpp$|\.c$|\.swift$|\.kt$"

# Check if this is a code file edit/write
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
    if echo "$TOOL_INPUT" | grep -qE "$CODE_EXTENSIONS"; then
        # Check if quality gates are enabled in project.yaml
        if [ -f "project.yaml" ]; then
            RUN_TESTS=$(grep -E "^\s+run_tests:" project.yaml | sed 's/.*: *//' | tr -d ' ')
            TYPECHECK=$(grep -E "^\s+typecheck:" project.yaml | sed 's/.*: *//' | tr -d ' ')
            LINT=$(grep -E "^\s+lint:" project.yaml | sed 's/.*: *//' | tr -d ' ')

            GATES_ENABLED=""
            [ "$RUN_TESTS" = "true" ] && GATES_ENABLED="${GATES_ENABLED}tests, "
            [ "$TYPECHECK" = "true" ] && GATES_ENABLED="${GATES_ENABLED}typecheck, "
            [ "$LINT" = "true" ] && GATES_ENABLED="${GATES_ENABLED}lint, "

            if [ -n "$GATES_ENABLED" ]; then
                GATES_ENABLED="${GATES_ENABLED%, }"  # Remove trailing comma
                cat << EOF
{
    "result": "continue",
    "message": "Quality Gates enabled: ${GATES_ENABLED}. Run these checks before marking the phase complete."
}
EOF
                exit 0
            fi
        fi
    fi
fi

echo '{"result": "continue"}'
