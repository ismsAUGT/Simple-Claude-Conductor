#!/bin/bash
# Project Executor - Main Execution Script
# Reads task-plan.md and orchestrates phase execution
#
# This script provides helper functions and utilities for the Claude-driven
# execution process. The actual orchestration is done by Claude using Task agents.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load configuration
CONFIG_FILE="$PROJECT_ROOT/project.yaml"
PLANNING_DIR="$PROJECT_ROOT/docs/planning"
TASK_PLAN="$PLANNING_DIR/task-plan.md"
FINDINGS="$PLANNING_DIR/findings.md"
PROGRESS="$PLANNING_DIR/progress.md"
REFERENCES="$PLANNING_DIR/references.md"

# Default configuration
DEFAULT_MODEL="sonnet"
BYPASS_PERMISSIONS="false"
INTERRUPT_QUESTIONS="true"
MAX_AUTO_PHASES="5"

# Validation configuration defaults
VALIDATION_ENABLED="true"
VALIDATION_MAX_TOKENS="10000"
VALIDATION_THRESHOLD="0.8"
VALIDATION_MAX_SAMPLES="10"
VALIDATION_SKIP_KEYWORDS="architecture security complex"

# Iteration configuration defaults
ITERATION_ENABLED="true"
ITERATION_MAX_TOKENS="5000"
ITERATION_SAMPLE_SIZE="10"
ITERATION_ERROR_THRESHOLD="0.1"
ITERATION_MAX_ITERATIONS="1"
ITERATION_SKIP_KEYWORDS="draft prototype quick"

# Parse YAML config (simplified - real implementation would use yq or python)
parse_config() {
    if [ -f "$CONFIG_FILE" ]; then
        DEFAULT_MODEL=$(grep -E "^\s+default_model:" "$CONFIG_FILE" | sed 's/.*: *"//' | sed 's/".*//' || echo "sonnet")
        BYPASS_PERMISSIONS=$(grep -E "^\s+bypass_permissions:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "false")
        INTERRUPT_QUESTIONS=$(grep -E "^\s+interrupt_for_questions:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "true")
        MAX_AUTO_PHASES=$(grep -E "^\s+max_auto_phases:" "$CONFIG_FILE" | sed 's/.*: *//' || echo "5")
    fi
}

# Parse validation config from project.yaml
parse_validation_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Check if validation section exists
        if grep -q "^validation:" "$CONFIG_FILE"; then
            VALIDATION_ENABLED=$(grep -A10 "^validation:" "$CONFIG_FILE" | grep -E "^\s+enabled:" | head -1 | sed 's/.*: *//' || echo "true")
            VALIDATION_MAX_TOKENS=$(grep -A10 "^validation:" "$CONFIG_FILE" | grep -E "^\s+max_tokens:" | head -1 | sed 's/.*: *//' || echo "10000")
            VALIDATION_THRESHOLD=$(grep -A10 "^validation:" "$CONFIG_FILE" | grep -E "^\s+confidence_threshold:" | head -1 | sed 's/.*: *//' || echo "0.8")
            VALIDATION_MAX_SAMPLES=$(grep -A10 "^validation:" "$CONFIG_FILE" | grep -E "^\s+max_sample_items:" | head -1 | sed 's/.*: *//' || echo "10")
        fi
    fi
}

# Check if validation should be skipped based on task keywords
should_skip_validation() {
    local task_description="$1"

    # Check for skip keywords
    for kw in $VALIDATION_SKIP_KEYWORDS; do
        if echo "$task_description" | grep -qi "$kw"; then
            echo "true"
            return
        fi
    done

    echo "false"
}

# Generate validation context for a task
generate_validation_context() {
    local task="$1"

    cat << EOF
## Quick Validation Phase
You are testing whether a simple approach works for this task.

### Task
$task

### Instructions
1. Sample up to $VALIDATION_MAX_SAMPLES items (if task involves multiple items)
2. Try the most straightforward approach first
3. Check if results are correct
4. Report confidence level (0-100%)

### Budget
- Max tokens: $VALIDATION_MAX_TOKENS
- Do NOT generate a full plan yet

### Report Format
VALIDATION_RESULT:
- approach_tested: [brief description]
- sample_size: [N]
- success_rate: [X/N correct]
- confidence: [0-100]%
- blockers: [list any issues]
- recommendation: SIMPLE_PLAN | FULL_PLANNING

### Decision Criteria
- If confidence >= $(echo "$VALIDATION_THRESHOLD * 100" | bc)%: Recommend SIMPLE_PLAN
- If confidence < $(echo "$VALIDATION_THRESHOLD * 100" | bc)%: Recommend FULL_PLANNING
EOF
}

# Parse iteration config from project.yaml
parse_iteration_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Check if iteration section exists
        if grep -q "^iteration:" "$CONFIG_FILE"; then
            ITERATION_ENABLED=$(grep -A10 "^iteration:" "$CONFIG_FILE" | grep -E "^\s+enabled:" | head -1 | sed 's/.*: *//' || echo "true")
            ITERATION_MAX_TOKENS=$(grep -A10 "^iteration:" "$CONFIG_FILE" | grep -E "^\s+max_tokens:" | head -1 | sed 's/.*: *//' || echo "5000")
            ITERATION_SAMPLE_SIZE=$(grep -A10 "^iteration:" "$CONFIG_FILE" | grep -E "^\s+sample_size:" | head -1 | sed 's/.*: *//' || echo "10")
            ITERATION_ERROR_THRESHOLD=$(grep -A10 "^iteration:" "$CONFIG_FILE" | grep -E "^\s+error_threshold:" | head -1 | sed 's/.*: *//' || echo "0.1")
            ITERATION_MAX_ITERATIONS=$(grep -A10 "^iteration:" "$CONFIG_FILE" | grep -E "^\s+max_iterations:" | head -1 | sed 's/.*: *//' || echo "1")
        fi
    fi
}

# Check if iteration should be skipped based on task keywords
should_skip_iteration() {
    local task_description="$1"

    # Check for skip keywords
    for kw in $ITERATION_SKIP_KEYWORDS; do
        if echo "$task_description" | grep -qi "$kw"; then
            echo "true"
            return
        fi
    done

    echo "false"
}

# Generate iteration context for post-execution self-check
generate_iteration_context() {
    local task="$1"
    local outputs="$2"

    local threshold_percent=$(echo "$ITERATION_ERROR_THRESHOLD * 100" | bc 2>/dev/null || echo "10")

    cat << EOF
## Quick Iteration Phase
You are self-checking outputs before final delivery.

### Task Summary
$task

### Outputs to Check
$outputs

### Instructions
1. Sample $ITERATION_SAMPLE_SIZE items from outputs
2. Check each against these criteria:
   - Correctness: Does it match requirements?
   - Completeness: Are all parts present?
   - Consistency: Do patterns match across outputs?
   - Format: Does it follow expected structure?
3. Identify any errors found
4. Report error rate and patterns

### Budget
- Max tokens: $ITERATION_MAX_TOKENS
- This is a QUICK check, not a full review
- Focus on obvious/cheap success criteria

### Report Format
ITERATION_RESULT:
- sample_size: [N]
- errors_found: [count]
- error_rate: [X]%
- error_patterns: [list common issues]
- recommendation: DELIVER | FIX_AND_DELIVER

### Decision Criteria
- If error_rate <= ${threshold_percent}%: Recommend DELIVER
- If error_rate > ${threshold_percent}%: Recommend FIX_AND_DELIVER

If FIX_AND_DELIVER:
- List specific fixes needed (max 3)
- Apply fixes within token budget
- Do NOT expand scope
- This is iteration 1 of $ITERATION_MAX_ITERATIONS (no more after this)
EOF
}

# Check if planning files exist
check_planning_files() {
    local missing=()

    [ ! -f "$TASK_PLAN" ] && missing+=("task-plan.md")
    [ ! -f "$FINDINGS" ] && missing+=("findings.md")
    [ ! -f "$PROGRESS" ] && missing+=("progress.md")
    [ ! -f "$REFERENCES" ] && missing+=("references.md")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing planning files: ${missing[*]}"
        echo "Run: bash .claude/skills/planning-with-files/scripts/init-planning.sh"
        return 1
    fi

    return 0
}

# Extract phases from task-plan.md
extract_phases() {
    # Extract phase names and their status
    grep -E "^### Phase [0-9]+:" "$TASK_PLAN" | while read -r line; do
        phase_num=$(echo "$line" | grep -oE "Phase [0-9]+" | grep -oE "[0-9]+")
        phase_name=$(echo "$line" | sed 's/^### Phase [0-9]*: *//')
        echo "$phase_num|$phase_name"
    done
}

# Get phase status
get_phase_status() {
    local phase_num="$1"
    local status=$(grep -A3 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Status\*\*:" | sed 's/.*: *//')
    echo "${status:-Not Started}"
}

# Get phase complexity
get_phase_complexity() {
    local phase_num="$1"
    local complexity=$(grep -A4 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Complexity\*\*:" | sed 's/.*: *//')
    echo "${complexity:-Medium}"
}

# Get phase model
get_phase_model() {
    local phase_num="$1"
    local model=$(grep -A5 "^### Phase $phase_num:" "$TASK_PLAN" | grep -E "^\*\*Model\*\*:" | sed 's/.*: *//')
    echo "${model:-$DEFAULT_MODEL}"
}

# Determine model from complexity (if not explicitly set)
complexity_to_model() {
    local complexity="$1"
    case "$complexity" in
        Low|low)    echo "haiku" ;;
        Medium|medium) echo "sonnet" ;;
        High|high)  echo "opus" ;;
        *)          echo "$DEFAULT_MODEL" ;;
    esac
}

# Score complexity based on phase description
score_complexity() {
    local description="$1"
    local score=0

    # High complexity keywords
    for kw in architecture design complex algorithm security debug optimize; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 3))
        fi
    done

    # Medium complexity keywords
    for kw in implement build create refactor test integrate; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 2))
        fi
    done

    # Low complexity keywords
    for kw in format rename move document simple update fix; do
        if echo "$description" | grep -qi "$kw"; then
            score=$((score + 1))
        fi
    done

    # Return complexity level
    if [ $score -ge 6 ]; then
        echo "High"
    elif [ $score -ge 3 ]; then
        echo "Medium"
    else
        echo "Low"
    fi
}

# Find next phase to execute
find_next_phase() {
    extract_phases | while IFS='|' read -r num name; do
        status=$(get_phase_status "$num")
        if [ "$status" = "Not Started" ] || [ "$status" = "In Progress" ]; then
            echo "$num"
            return
        fi
    done
}

# Generate context injection for a phase
generate_context_injection() {
    local phase_num="$1"

    echo "## Context Injection"
    echo "You are executing Phase $phase_num"
    echo ""

    # Goal
    echo "### Project Goal"
    sed -n '/^## Goal/,/^## /p' "$TASK_PLAN" | head -n -1 | tail -n +2
    echo ""

    # Phase requirements
    echo "### Phase Requirements"
    sed -n "/^### Phase $phase_num:/,/^### Phase/p" "$TASK_PLAN" | head -n -1
    echo ""

    # Last 2 progress entries
    echo "### Previous Progress"
    grep -A20 "^### Session" "$PROGRESS" | head -40
    echo ""

    # Instructions
    cat << 'EOF'
### Your Instructions
1. Complete all deliverables listed above
2. Update docs/planning/findings.md for any research (2-Action Rule)
3. Update docs/planning/progress.md when phase is complete
4. Check off completed deliverables in task-plan.md
5. Report any blockers immediately
EOF
}

# Main execution status
show_status() {
    echo "========================================"
    echo "  Project Execution Status"
    echo "========================================"
    echo ""
    echo "Configuration:"
    echo "  Default Model: $DEFAULT_MODEL"
    echo "  Bypass Permissions: $BYPASS_PERMISSIONS"
    echo "  Interrupt for Questions: $INTERRUPT_QUESTIONS"
    echo "  Max Auto Phases: $MAX_AUTO_PHASES"
    echo ""
    echo "Phases:"
    extract_phases | while IFS='|' read -r num name; do
        status=$(get_phase_status "$num")
        complexity=$(get_phase_complexity "$num")
        model=$(get_phase_model "$num")
        printf "  Phase %s: %-30s [%s] %s/%s\n" "$num" "$name" "$status" "$complexity" "$model"
    done
    echo ""
    echo "Next phase: $(find_next_phase)"
}

# Command handling
case "${1:-status}" in
    status)
        parse_config
        check_planning_files && show_status
        ;;
    check)
        check_planning_files && echo "All planning files present."
        ;;
    context)
        parse_config
        check_planning_files && generate_context_injection "${2:-1}"
        ;;
    next)
        parse_config
        check_planning_files && find_next_phase
        ;;
    validation)
        parse_config
        parse_validation_config
        task="${2:-}"
        if [ -z "$task" ]; then
            echo "Usage: $0 validation \"task description\""
            exit 1
        fi
        echo "========================================"
        echo "  Quick Validation Check"
        echo "========================================"
        echo ""
        echo "Task: $task"
        echo "Validation Enabled: $VALIDATION_ENABLED"
        echo "Token Budget: $VALIDATION_MAX_TOKENS"
        echo "Max Samples: $VALIDATION_MAX_SAMPLES"
        echo "Confidence Threshold: $VALIDATION_THRESHOLD"
        echo ""
        if [ "$(should_skip_validation "$task")" = "true" ]; then
            echo "DECISION: Skip validation (complexity keywords detected)"
            echo "RECOMMENDATION: FULL_PLANNING"
        else
            echo "--- Validation Context ---"
            generate_validation_context "$task"
            echo "--- End Context ---"
        fi
        ;;
    iteration)
        parse_config
        parse_iteration_config
        task="${2:-}"
        outputs="${3:-}"
        if [ -z "$task" ]; then
            echo "Usage: $0 iteration \"task description\" \"outputs to check\""
            exit 1
        fi
        echo "========================================"
        echo "  Quick Iteration Check"
        echo "========================================"
        echo ""
        echo "Task: $task"
        echo "Iteration Enabled: $ITERATION_ENABLED"
        echo "Token Budget: $ITERATION_MAX_TOKENS"
        echo "Sample Size: $ITERATION_SAMPLE_SIZE"
        echo "Error Threshold: $ITERATION_ERROR_THRESHOLD"
        echo "Max Iterations: $ITERATION_MAX_ITERATIONS"
        echo ""
        if [ "$ITERATION_ENABLED" = "false" ]; then
            echo "DECISION: Iteration disabled in project.yaml"
            echo "RECOMMENDATION: DELIVER"
        elif [ "$(should_skip_iteration "$task")" = "true" ]; then
            echo "DECISION: Skip iteration (task type keywords detected)"
            echo "RECOMMENDATION: DELIVER"
        else
            echo "--- Iteration Context ---"
            generate_iteration_context "$task" "$outputs"
            echo "--- End Context ---"
        fi
        ;;
    run)
        # Run all phases sequentially using Task agents
        parse_config
        parse_validation_config
        parse_iteration_config

        if ! check_planning_files; then
            exit 1
        fi

        echo "========================================"
        echo "  Project Execution - Running All Phases"
        echo "========================================"
        echo ""

        # Get list of phases
        PHASES=$(extract_phases)
        TOTAL_PHASES=$(echo "$PHASES" | wc -l)
        COMPLETED=0

        echo "Total phases: $TOTAL_PHASES"
        echo ""

        # Execute each phase
        echo "$PHASES" | while IFS='|' read -r num name; do
            status=$(get_phase_status "$num")

            if [ "$status" = "Complete" ] || [ "$status" = "Completed" ]; then
                echo "Phase $num: $name - SKIPPED (already complete)"
                COMPLETED=$((COMPLETED + 1))
                continue
            fi

            # Determine model for this phase
            explicit_model=$(get_phase_model "$num")
            if [ "$explicit_model" = "$DEFAULT_MODEL" ]; then
                # No explicit model, use complexity scoring
                complexity=$(score_complexity "$name")
                model=$(complexity_to_model "$complexity")
            else
                model="$explicit_model"
            fi

            echo ""
            echo "========================================"
            echo "  Phase $num: $name"
            echo "  Model: $model"
            echo "========================================"
            echo ""

            # Run the phase using run-phase.sh
            "$SCRIPT_DIR/run-phase.sh" "$num" "$model"

            echo ""
            echo "Phase $num complete. Continuing to next phase..."
            echo ""
        done

        echo ""
        echo "========================================"
        echo "  Execution Complete"
        echo "========================================"
        echo ""
        show_status
        ;;

    phase)
        # Run a specific phase
        parse_config
        if ! check_planning_files; then
            exit 1
        fi

        phase_num="${2:-}"
        model="${3:-}"

        if [ -z "$phase_num" ]; then
            echo "Usage: $0 phase <phase_number> [model]"
            exit 1
        fi

        # If no model specified, determine from complexity
        if [ -z "$model" ]; then
            explicit_model=$(get_phase_model "$phase_num")
            if [ "$explicit_model" = "$DEFAULT_MODEL" ]; then
                phase_name=$(grep "^### Phase $phase_num:" "$TASK_PLAN" | sed 's/^### Phase [0-9]*: *//')
                complexity=$(score_complexity "$phase_name")
                model=$(complexity_to_model "$complexity")
            else
                model="$explicit_model"
            fi
        fi

        echo "Running Phase $phase_num with model: $model"
        "$SCRIPT_DIR/run-phase.sh" "$phase_num" "$model"
        ;;

    *)
        echo "Usage: $0 {status|check|context [phase_num]|next|run|phase <num> [model]|validation \"task\"|iteration \"task\" \"outputs\"}"
        echo ""
        echo "Commands:"
        echo "  status              Show current project status"
        echo "  check               Verify planning files exist"
        echo "  context [phase]     Generate context injection for a phase"
        echo "  next                Show next phase to execute"
        echo "  run                 Execute all phases sequentially (spawns subagents)"
        echo "  phase <num> [model] Execute a specific phase with optional model override"
        echo "  validation \"task\"  Generate validation context for a task"
        echo "  iteration \"task\"   Generate iteration context for post-check"
        exit 1
        ;;
esac
