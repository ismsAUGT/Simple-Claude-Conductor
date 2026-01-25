#!/bin/bash
# phase-completion-check.sh
# Ensures validation was documented before marking phase complete

PROGRESS_FILE="docs/planning/progress.md"

# Check if progress.md exists
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "REMINDER: Run output-validation skill before marking phase complete."
    echo "progress.md does not exist yet."
    exit 0
fi

# Check if any validation entry exists
if ! grep -q "## Validation:" "$PROGRESS_FILE"; then
    echo "REMINDER: Run output-validation skill before marking phase complete."
    echo "progress.md has no validation entries."
    exit 0
fi

# All checks passed
exit 0
