#!/bin/bash
# Claude Project Executor - First-run Initialization
# This script sets up the project for use with Claude Project Executor

set -e

echo "========================================"
echo "  Claude Project Executor Setup"
echo "========================================"
echo ""

# Default values
DEFAULT_PROJECT_NAME="My Project"
DEFAULT_MODEL="sonnet"
DEFAULT_BYPASS="false"
DEFAULT_INTERRUPT="true"

# Check if running interactively
if [ -t 0 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local varname="$3"

    if [ "$INTERACTIVE" = true ]; then
        read -p "$prompt [$default]: " value
        value="${value:-$default}"
    else
        value="$default"
    fi
    eval "$varname='$value'"
}

# Gather configuration
echo "Project Configuration"
echo "---------------------"

prompt_with_default "Project name" "$DEFAULT_PROJECT_NAME" PROJECT_NAME
prompt_with_default "Default model (haiku/sonnet/opus)" "$DEFAULT_MODEL" DEFAULT_MODEL_CHOICE
prompt_with_default "Bypass permissions (true/false)" "$DEFAULT_BYPASS" BYPASS_PERMS
prompt_with_default "Interrupt for questions (true/false)" "$DEFAULT_INTERRUPT" INTERRUPT_QS

echo ""
echo "Setting up with:"
echo "  Project name: $PROJECT_NAME"
echo "  Default model: $DEFAULT_MODEL_CHOICE"
echo "  Bypass permissions: $BYPASS_PERMS"
echo "  Interrupt for questions: $INTERRUPT_QS"
echo ""

# Update project.yaml with user values
if [ -f "project.yaml" ]; then
    echo "Updating project.yaml..."

    # Cross-platform sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/name: \"My Project\"/name: \"$PROJECT_NAME\"/" project.yaml
        sed -i '' "s/default_model: \"sonnet\"/default_model: \"$DEFAULT_MODEL_CHOICE\"/" project.yaml
        sed -i '' "s/bypass_permissions: false/bypass_permissions: $BYPASS_PERMS/" project.yaml
        sed -i '' "s/interrupt_for_questions: true/interrupt_for_questions: $INTERRUPT_QS/" project.yaml
    else
        sed -i "s/name: \"My Project\"/name: \"$PROJECT_NAME\"/" project.yaml
        sed -i "s/default_model: \"sonnet\"/default_model: \"$DEFAULT_MODEL_CHOICE\"/" project.yaml
        sed -i "s/bypass_permissions: false/bypass_permissions: $BYPASS_PERMS/" project.yaml
        sed -i "s/interrupt_for_questions: true/interrupt_for_questions: $INTERRUPT_QS/" project.yaml
    fi
fi

# Initialize planning files
echo "Initializing planning files..."
if [ -f ".claude/skills/planning-with-files/scripts/init-planning.sh" ]; then
    bash .claude/skills/planning-with-files/scripts/init-planning.sh "$PROJECT_NAME"
else
    # Fallback: create directories manually
    mkdir -p docs/planning/reports docs/planning/archive

    # Create minimal planning files
    DATE=$(date +%Y-%m-%d)

    if [ ! -f "docs/planning/task-plan.md" ]; then
        cat > docs/planning/task-plan.md << EOF
# Task: $PROJECT_NAME

**Created**: $DATE
**Status**: Not Started

## Goal
[Describe your goal here]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Phases
[Phases will be generated when you provide a prompt]
EOF
        echo "  Created docs/planning/task-plan.md"
    fi

    if [ ! -f "docs/planning/findings.md" ]; then
        cat > docs/planning/findings.md << EOF
# Findings: $PROJECT_NAME

**Last Updated**: $DATE

## Summary
[Research findings will be documented here]

## Discoveries
[Add discoveries as you research]
EOF
        echo "  Created docs/planning/findings.md"
    fi

    if [ ! -f "docs/planning/progress.md" ]; then
        cat > docs/planning/progress.md << EOF
# Progress: $PROJECT_NAME

**Started**: $DATE
**Current Phase**: Not Started

## Session Log
[Session entries will be added as you work]
EOF
        echo "  Created docs/planning/progress.md"
    fi

    if [ ! -f "docs/planning/references.md" ]; then
        cat > docs/planning/references.md << EOF
# References: $PROJECT_NAME

**Last Updated**: $DATE

## Key Files
[Files will be cataloged here as they are discovered]
EOF
        echo "  Created docs/planning/references.md"
    fi
fi

# Make hook scripts executable
echo "Making hook scripts executable..."
chmod +x .claude/hooks/*.sh 2>/dev/null || true
chmod +x .claude/skills/*/scripts/*.sh 2>/dev/null || true

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Start Claude Code in this directory"
echo "  2. Provide a prompt describing what you want to build"
echo "  3. Claude will generate a plan and ask clarifying questions"
echo "  4. Review and approve the plan"
echo "  5. Claude executes each phase automatically"
echo ""
echo "Key files:"
echo "  - project.yaml          : Project configuration"
echo "  - docs/planning/        : Planning files"
echo "  - .claude/              : Claude configuration"
echo "  - CLAUDE.md             : Quick reference for Claude"
echo ""
echo "Example prompts:"
echo '  "Build a REST API for user management with JWT auth"'
echo '  "Create a React dashboard with data visualization"'
echo '  "Refactor the authentication system to use OAuth2"'
echo ""
