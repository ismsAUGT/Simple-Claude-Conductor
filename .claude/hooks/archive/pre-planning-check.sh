#!/bin/bash
# pre-planning-check.sh
# Ensures Domain Understanding section exists before planning

FINDINGS_FILE="docs/planning/findings.md"

# Check if findings.md exists
if [ ! -f "$FINDINGS_FILE" ]; then
    echo "REMINDER: Run prompt-understanding skill before planning."
    echo "findings.md does not exist yet."
    exit 0  # Exit 0 = reminder mode (warn but allow)
    # Change to exit 1 for block mode
fi

# Check if Domain Understanding section exists
if ! grep -q "## Domain Understanding" "$FINDINGS_FILE"; then
    echo "REMINDER: Run prompt-understanding skill before planning."
    echo "findings.md is missing the 'Domain Understanding' section."
    exit 0
fi

# Check if Domain Understanding section has content (not just the header)
CONTENT=$(sed -n '/## Domain Understanding/,/^## /p' "$FINDINGS_FILE" | grep -v "^#" | grep -v "^$" | head -5)
if [ -z "$CONTENT" ]; then
    echo "REMINDER: Run prompt-understanding skill before planning."
    echo "The 'Domain Understanding' section in findings.md is empty."
    exit 0
fi

# All checks passed
exit 0
