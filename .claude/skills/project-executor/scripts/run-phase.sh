#!/bin/bash
# Run Phase - Spawns a Claude subagent to execute a specific phase
#
# Usage: ./run-phase.sh <phase_number> [model]
#
# This script is the KEY to delegation - it spawns a SEPARATE Claude instance
# to do the actual implementation work, keeping the main session focused on
# orchestration only.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Configuration
PLANNING_DIR="$PROJECT_ROOT/docs/planning"
TASK_PLAN="$PLANNING_DIR/task-plan.md"
FINDINGS="$PLANNING_DIR/findings.md"
PROGRESS="$PLANNING_DIR/progress.md"
CONFIG_FILE="$PROJECT_ROOT/project.yaml"

# Parse arguments
PHASE_NUM="${1:-}"
MODEL="${2:-sonnet}"

if [ -z "$PHASE_NUM" ]; then
    echo "Usage: $0 <phase_number> [model]"
    echo ""
    echo "Models: haiku, sonnet, opus"
    echo "Example: $0 2 sonnet"
    exit 1
fi

# Validate phase exists
if ! grep -q "^### Phase $PHASE_NUM:" "$TASK_PLAN" 2>/dev/null; then
    echo "Error: Phase $PHASE_NUM not found in $TASK_PLAN"
    exit 1
fi

# Extract phase information
PHASE_NAME=$(grep "^### Phase $PHASE_NUM:" "$TASK_PLAN" | sed 's/^### Phase [0-9]*: *//')
PHASE_STATUS=$(grep -A3 "^### Phase $PHASE_NUM:" "$TASK_PLAN" | grep -E "^\*\*Status\*\*:" | sed 's/.*: *//' || echo "Not Started")

echo "========================================"
echo "  Spawning Phase $PHASE_NUM Agent"
echo "========================================"
echo ""
echo "Phase: $PHASE_NAME"
echo "Model: $MODEL"
echo "Status: $PHASE_STATUS"
echo ""

# Check if phase is already complete
if [ "$PHASE_STATUS" = "Complete" ] || [ "$PHASE_STATUS" = "Completed" ]; then
    echo "Warning: Phase $PHASE_NUM is already complete."
    read -p "Run anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Generate context injection
generate_context() {
    cat << CONTEXT_EOF
## Context Injection - Phase $PHASE_NUM: $PHASE_NAME

You are a Task agent executing Phase $PHASE_NUM of a project plan.

### Your Role
You are responsible for the IMPLEMENTATION work of this phase.
- Write code, create files, make edits
- Run tests as needed
- Complete all deliverables listed below
- Update progress files when done

### Project Goal
$(sed -n '/^## Goal/,/^## /p' "$TASK_PLAN" | head -n -1 | tail -n +2)

### Phase $PHASE_NUM Requirements
$(sed -n "/^### Phase $PHASE_NUM:/,/^### Phase/p" "$TASK_PLAN" | head -n -1)

### Key Findings (Context)
$(tail -50 "$FINDINGS" 2>/dev/null || echo "No findings yet")

### Recent Progress
$(tail -30 "$PROGRESS" 2>/dev/null || echo "No progress logged yet")

### Your Instructions
1. Complete ALL deliverables listed for this phase
2. Update docs/planning/findings.md for any research discoveries (2-Action Rule)
3. After completing work, update docs/planning/progress.md with what you accomplished
4. Mark deliverables as complete (change [ ] to [x]) in task-plan.md
5. If you encounter blockers, document them and report back

### Important Notes
- You are a subagent - focus on THIS phase only
- Don't modify other phases or expand scope
- Quality over speed - get it right
- If unsure, document assumptions in findings.md
CONTEXT_EOF
}

# Create temporary prompt file
PROMPT_FILE=$(mktemp)
generate_context > "$PROMPT_FILE"

echo "Context injection created: $PROMPT_FILE"
echo ""
echo "--- Context Preview (first 50 lines) ---"
head -50 "$PROMPT_FILE"
echo "..."
echo "--- End Preview ---"
echo ""

# Determine model flag
case "$MODEL" in
    haiku)
        MODEL_FLAG="--model claude-haiku-3-5-20241022"
        ;;
    sonnet)
        MODEL_FLAG="--model claude-sonnet-4-20250514"
        ;;
    opus)
        MODEL_FLAG="--model claude-opus-4-5-20251101"
        ;;
    *)
        MODEL_FLAG="--model $MODEL"
        ;;
esac

# Mark phase as in progress
echo "Marking phase as In Progress..."
if command -v sed &> /dev/null; then
    # Try to update status in task-plan.md
    sed -i.bak "s/\(\*\*Status\*\*: *\)Not Started/\1In Progress/" "$TASK_PLAN" 2>/dev/null || true
fi

# Spawn the Claude subagent
echo ""
echo "========================================"
echo "  Launching Claude Agent for Phase $PHASE_NUM"
echo "  Model: $MODEL"
echo "========================================"
echo ""

# Run Claude with the context
# The --print-prompt flag can be useful for debugging
if [ -n "$DRY_RUN" ]; then
    echo "[DRY RUN] Would execute:"
    echo "claude $MODEL_FLAG --dangerously-skip-permissions < \"$PROMPT_FILE\""
else
    # Actually spawn Claude with the context
    # Using --dangerously-skip-permissions to avoid interrupts
    claude $MODEL_FLAG --dangerously-skip-permissions --prompt "$(cat "$PROMPT_FILE")"
fi

# Clean up
rm -f "$PROMPT_FILE"

echo ""
echo "========================================"
echo "  Phase $PHASE_NUM Agent Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Review the agent's work"
echo "  2. Check if deliverables are complete"
echo "  3. Run: ./execute-plan.sh status"
echo ""
