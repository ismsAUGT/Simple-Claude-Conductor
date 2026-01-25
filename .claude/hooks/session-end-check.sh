#!/bin/bash
# Hook: Session End Check (Stop)
# Verifies task completion before session ends
#
# Inspired by planning-with-files Stop hook pattern
#
# Actions:
# 1. Check all phases marked complete
# 2. Verify STATUS.md is updated
# 3. Check for validation entries in progress.md
# 4. Remind to run cost report

set -euo pipefail

TASK_PLAN="docs/planning/task-plan.md"
PROGRESS="docs/planning/progress.md"
STATUS="STATUS.md"
WARNINGS=()

# ============================================================================
# CHECK 1: All Phases Complete
# ============================================================================
if [ -f "$TASK_PLAN" ]; then
    # Count total phases
    TOTAL_PHASES=$(grep -c "^### Phase" "$TASK_PLAN" 2>/dev/null || echo "0")

    if [ "$TOTAL_PHASES" -gt 0 ]; then
        # Count completed phases (marked with [Complete] or similar)
        COMPLETED_PHASES=$(grep -cE "^### Phase.*\[(Complete|Done|Finished)\]" "$TASK_PLAN" 2>/dev/null || echo "0")

        if [ "$COMPLETED_PHASES" -lt "$TOTAL_PHASES" ]; then
            INCOMPLETE=$((TOTAL_PHASES - COMPLETED_PHASES))
            WARNINGS+=("INCOMPLETE: $INCOMPLETE of $TOTAL_PHASES phases not marked complete in task-plan.md")
        fi
    fi
else
    # No task plan - might be a quick task, don't warn
    :
fi

# ============================================================================
# CHECK 2: STATUS.md Updated Recently
# ============================================================================
if [ -f "$STATUS" ]; then
    # Check if STATUS.md mentions completion or has recent update
    if ! grep -qE "(Complete|Finished|Done|WHAT TO DO NEXT)" "$STATUS" 2>/dev/null; then
        WARNINGS+=("STATUS.md may be stale - update the 'WHAT TO DO NEXT' section")
    fi
else
    # Only warn if we have a task plan (indicates structured work)
    if [ -f "$TASK_PLAN" ]; then
        WARNINGS+=("STATUS.md not found - create it to communicate progress to users")
    fi
fi

# ============================================================================
# CHECK 3: Validation Documented
# ============================================================================
if [ -f "$TASK_PLAN" ]; then
    # Only check if we have phases (structured work)
    if grep -q "^### Phase" "$TASK_PLAN" 2>/dev/null; then
        if [ -f "$PROGRESS" ]; then
            if ! grep -qE "## Validation:|validation|verified|checked" "$PROGRESS" 2>/dev/null; then
                WARNINGS+=("No validation entries in progress.md - document what was verified")
            fi
        else
            WARNINGS+=("progress.md not found - document session work and validation")
        fi
    fi
fi

# ============================================================================
# CHECK 4: Cost Report Reminder
# ============================================================================
if [ -f "scripts/generate_cost_report.py" ]; then
    if [ ! -f "output/cost_report.md" ]; then
        WARNINGS+=("Run 'python scripts/generate_cost_report.py .' to generate cost report")
    fi
fi

# ============================================================================
# OUTPUT
# ============================================================================
if [ ${#WARNINGS[@]} -gt 0 ]; then
    # Format warnings as a list
    WARNING_LIST=""
    for w in "${WARNINGS[@]}"; do
        WARNING_LIST="${WARNING_LIST}- ${w}\n"
    done

    # Use printf to handle newlines properly
    MSG=$(printf "Session ending with warnings:\n$WARNING_LIST\nConsider addressing these before ending.")

    cat << EOF
{
    "result": "continue",
    "message": "$MSG"
}
EOF
else
    cat << 'EOF'
{
    "result": "continue",
    "message": "Session complete. All checks passed."
}
EOF
fi
