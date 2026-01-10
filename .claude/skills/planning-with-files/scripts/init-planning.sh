#!/bin/bash
# Initialize planning files for a new task
# Usage: ./init-planning.sh "Task Name"

set -e

TASK_NAME="${1:-My Project}"
DATE=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
PLANNING_DIR="docs/planning"

# Create planning directory if it doesn't exist
mkdir -p "$PLANNING_DIR"
mkdir -p "$PLANNING_DIR/reports"
mkdir -p "$PLANNING_DIR/archive"

# Function to copy and customize template
copy_template() {
    local template="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        echo "  Skipping $dest (already exists)"
        return
    fi

    cp "$TEMPLATE_DIR/$template" "$dest"

    # Replace placeholders
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/\[Task Name\]/$TASK_NAME/g" "$dest"
        sed -i '' "s/\[Date\]/$DATE/g" "$dest"
    else
        # Linux/Windows Git Bash
        sed -i "s/\[Task Name\]/$TASK_NAME/g" "$dest"
        sed -i "s/\[Date\]/$DATE/g" "$dest"
    fi

    echo "  Created $dest"
}

echo "Initializing planning files for: $TASK_NAME"
echo ""

# Copy templates
copy_template "task-plan.md" "$PLANNING_DIR/task-plan.md"
copy_template "findings.md" "$PLANNING_DIR/findings.md"
copy_template "progress.md" "$PLANNING_DIR/progress.md"
copy_template "references.md" "$PLANNING_DIR/references.md"

# Create README if it doesn't exist
if [ ! -f "$PLANNING_DIR/README.md" ]; then
    cat > "$PLANNING_DIR/README.md" << EOF
# Planning: $TASK_NAME

This folder contains the planning files for the current project.

## Files
- **task-plan.md** - Master plan with goal, phases, and decisions
- **findings.md** - Research discoveries and patterns
- **progress.md** - Session history and progress tracking
- **references.md** - File catalog and external resources

## Subfolders
- **reports/** - Generated summary reports
- **archive/** - Completed project archives

## Quick Reference
1. Re-read task-plan.md before major decisions
2. Update findings.md every 2 research operations (2-Action Rule)
3. Update progress.md at end of each session
4. Add files to references.md when discovered

Created: $DATE
EOF
    echo "  Created $PLANNING_DIR/README.md"
fi

echo ""
echo "Planning files initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit $PLANNING_DIR/task-plan.md to define your goal and phases"
echo "  2. Run Claude and provide your prompt"
echo "  3. Claude will generate a complete plan"
