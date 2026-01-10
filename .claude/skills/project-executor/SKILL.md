---
name: project-executor
description: Orchestrates plan execution with fresh agents per phase and automatic model selection. Generates plans from prompts, asks clarifying questions, and produces summaries.
---

# Project Executor

The orchestration layer that transforms prompts into executed plans. Works with the `planning-with-files` skill to maintain context across phases.

## Prerequisites

1. Planning files initialized (`planning-with-files` skill)
2. `project.yaml` configured
3. User has provided a prompt or `task-plan.md` has phases defined

## Capabilities

### 1. Plan Generation
Transform a user prompt into a structured plan:
- Parse prompt to identify goals and requirements
- Generate phases with deliverables
- Assign complexity and model to each phase
- Identify risks and assumptions
- Ask clarifying questions (if `interrupt_for_questions: true`)

### 2. Phase Execution
Execute each phase with optimal settings:
- Determine complexity using scoring algorithm
- Select appropriate model (haiku/sonnet/opus)
- Spawn fresh Task agent with context injection
- Monitor completion and validate deliverables
- Update planning files as work progresses

### 3. Summary Generation
After execution completes:
- Generate executive summary
- Extract lessons learned
- Archive completed project
- Provide recommendations

## Execution Flow

```
1. Read task-plan.md
   └─> If no phases: Generate plan from prompt
   └─> If phases exist: Proceed to execution

2. For each phase:
   a. Determine complexity
   b. Select model
   c. Prepare context injection
   d. Spawn Task agent
   e. Agent executes
   f. Validate deliverables
   g. Update progress.md
   h. Mark phase complete

3. After all phases:
   a. Generate executive summary
   b. Extract lessons learned
   c. Archive if requested
```

## Complexity Scoring

The model selection algorithm scores phase complexity:

### Keyword Analysis (0-3 points each)
**High complexity keywords** (+3): architecture, design, complex, algorithm, security, debug, optimize
**Medium complexity keywords** (+2): implement, build, create, refactor, test, integrate
**Low complexity keywords** (+1): format, rename, move, document, simple, update, fix

### File Count Factor
- 10+ files: +3 points
- 5-10 files: +2 points
- 2-5 files: +1 point
- 1 file: +0 points

### Scoring Thresholds
- Score >= 6: **High** → Opus
- Score >= 3: **Medium** → Sonnet
- Score < 3: **Low** → Haiku

### Explicit Override
If `task-plan.md` specifies `**Model**: [model]` for a phase, that overrides the algorithm.

## Context Injection Template

When spawning a phase agent, inject this context:

```markdown
## Context Injection
You are executing Phase [N]: [Phase Name]

### Project Goal
[From task-plan.md Goal section]

### Phase Requirements
[From task-plan.md - this phase's deliverables and description]

### Relevant Findings
[From findings.md - entries relevant to this phase, filtered by keywords]

### Key Files
[From references.md - files this phase will likely touch]

### Previous Progress
[From progress.md - last 2 session entries for continuity]

### Your Instructions
1. Complete all deliverables listed above
2. Update docs/planning/findings.md for any research (2-Action Rule)
3. Update docs/planning/progress.md when phase is complete
4. Check off completed deliverables in task-plan.md
5. Report any blockers immediately - do not proceed if blocked
```

## Plan Generation Prompts

### Initial Plan Generation (Opus)
```
Given this user request:
[USER PROMPT]

Generate a project plan with:
1. Goal statement (1-2 sentences)
2. Success criteria (3-5 measurable outcomes)
3. Phases (3-7 phases, each with deliverables)
4. Risks and mitigations
5. Key assumptions

For each phase, specify:
- Name and description
- Deliverables (as checkboxes)
- Complexity (Low/Medium/High)
- Recommended model (Haiku/Sonnet/Opus)

Format as markdown matching the task-plan.md template.
```

### Clarifying Questions (Sonnet)
```
Review this plan:
[GENERATED PLAN]

Identify 3-5 clarifying questions that would:
1. Resolve ambiguities in requirements
2. Clarify technical decisions (frameworks, databases, etc.)
3. Understand constraints (time, resources, existing systems)
4. Validate assumptions

Prioritize blocking questions (those that could significantly change the plan).
```

## Scripts

### execute-plan.sh
Main execution orchestrator. Reads `task-plan.md`, processes phases sequentially, spawns agents, and tracks progress.

### generate-summary.sh
Post-execution summary generator. Aggregates progress, extracts lessons, produces final report.

### run-quality-gates.sh
Auto-detects project type and runs quality checks. Supports:
- **Tests**: npm test, pytest, go test, cargo test, mvn test
- **Typecheck**: tsc, mypy, pyright, go build, cargo check
- **Lint**: eslint, ruff, flake8, golangci-lint, cargo clippy

Usage:
```bash
./run-quality-gates.sh tests      # Run tests only
./run-quality-gates.sh typecheck  # Run type checking only
./run-quality-gates.sh lint       # Run linter only
./run-quality-gates.sh all        # Run all checks
./run-quality-gates.sh detect     # Show detected project type
```

## Quality Gates

Quality gates are optional validation steps that run before marking a phase complete.

### Configuration (project.yaml)

```yaml
quality_gates:
  run_tests: true    # Auto-detect and run tests
  typecheck: true    # Auto-detect and run type checker
  lint: false        # Auto-detect and run linter
```

### When Quality Gates Run

1. After completing implementation work in a phase
2. Before marking the phase as "Complete" in task-plan.md
3. If any gate fails, the phase remains "In Progress"

### Gate Execution Flow

```
Phase implementation complete
        │
        ▼
┌─────────────────┐
│ Run Tests       │──▶ FAIL ──▶ Fix issues, retry
└────────┬────────┘
         │ PASS
         ▼
┌─────────────────┐
│ Run Typecheck   │──▶ FAIL ──▶ Fix issues, retry
└────────┬────────┘
         │ PASS
         ▼
┌─────────────────┐
│ Run Lint        │──▶ FAIL ──▶ Fix issues, retry
└────────┬────────┘
         │ PASS
         ▼
   Mark phase complete
```

### Handling Failures

When a quality gate fails:
1. Do NOT mark the phase complete
2. Fix the failing tests/types/lint issues
3. Re-run the quality gates
4. Only proceed when all enabled gates pass

## Test-First Development Mode

When `execution.test_first: true` is set, implementation phases follow TDD:

### TDD Flow (RED → GREEN → REFACTOR)

```
1. RED: Write failing tests first
   - Define expected behavior
   - Tests should fail initially

2. GREEN: Write minimal code to pass
   - Implement just enough to pass tests
   - Don't over-engineer

3. REFACTOR: Clean up
   - Improve code quality
   - Ensure tests still pass
```

### When Test-First Applies

Test-first mode activates for phases with:
- Complexity: Medium or High
- Keywords: "implement", "build", "create", "add feature"

Test-first mode skips for:
- Documentation phases
- Configuration phases
- Research/exploration phases
- Phases explicitly marked `**Test-First**: false`

### Phase Modification

When test-first is enabled, implementation phases are split:

**Original Phase:**
```markdown
### Phase 3: User Authentication
**Deliverables**:
- [ ] Login endpoint
- [ ] JWT token generation
- [ ] Password hashing
```

**With Test-First:**
```markdown
### Phase 3a: User Authentication - Tests
**Deliverables**:
- [ ] Test: login with valid credentials
- [ ] Test: login with invalid credentials
- [ ] Test: JWT token structure
- [ ] Test: password hash verification

### Phase 3b: User Authentication - Implementation
**Deliverables**:
- [ ] Login endpoint (tests passing)
- [ ] JWT token generation (tests passing)
- [ ] Password hashing (tests passing)
```

### Configuration

```yaml
execution:
  test_first: true  # Enable TDD mode

quality_gates:
  run_tests: true   # Required for test-first to work
```

## Configuration

Settings from `project.yaml`:
- `execution.default_model`: Fallback model if complexity scoring fails
- `execution.bypass_permissions`: Skip confirmations during execution
- `execution.interrupt_for_questions`: Whether to stop for clarifying questions
- `execution.max_auto_phases`: Limit on automatic phase execution
- `execution.generate_summary`: Whether to generate summary after completion

## Error Handling

### Agent Failures
1. Log error in `task-plan.md` Errors table
2. Attempt retry with same context
3. If retry fails, mark phase as blocked
4. Notify user for manual intervention

### Context Issues
1. If planning files are missing, prompt to initialize
2. If phase is unclear, ask for clarification
3. If deliverables can't be validated, mark for review

### Recovery
If execution is interrupted:
1. Read `task-plan.md` → Identify current phase
2. Read `progress.md` → Find last completed work
3. Resume from interruption point
4. No context lost due to persistent files

## Best Practices

1. **One phase at a time** - Never parallelize phases
2. **Fresh agent per phase** - Don't reuse agents across phases
3. **Minimal context** - Only inject relevant information
4. **Immediate updates** - Update files as work completes
5. **Validate deliverables** - Check each deliverable before marking complete
