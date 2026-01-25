---
name: project-executor
description: Orchestrates plan execution with fresh agents per phase and automatic model selection. Generates plans from prompts, asks clarifying questions, and produces summaries.
---

# Project Executor

The orchestration layer that transforms prompts into executed plans. Works with the `planning-with-files` skill to maintain context across phases.

## Execution Strategy: Stay In-Session by Default

**Core Principle**: Don't spawn subagents unless the benefit clearly outweighs the cache cost.

### Why This Matters

| Approach | Tokens | Time | Best For |
|----------|--------|------|----------|
| Single-session | Lower (cache reuse) | Faster | Implementation with shared files |
| Multi-agent | Higher (cache breaks) | Slower | Independent research tasks |

**Research finding**: Multi-agent runs used ~15x more tokens than single-agent on same tasks (Anthropic).

### Simple Decision Rule

Ask: **"Will a subagent need to read the same large files I already have cached?"**

- **YES** → Stay in-session (cache sharing is valuable)
- **NO** → Consider delegating (isolated context is fine)

### When to Stay In-Session (Default)

- All phases need the same reference files
- Implementation/coding work
- Sequential dependencies between phases
- Files total > 50K tokens shared across phases

### When to Delegate

- Pure research/exploration with no shared files
- Validation/testing of outputs (discrete, bounded)
- Tasks explicitly marked "parallelize" in plan
- Independent directions needing different context

### Practical Guidelines

1. **Default**: Work in main session with file-based planning
2. **Max subagents**: 2-3 for a full project (not 9!)
3. **Context passing**: Send file paths, not file contents
4. **Compaction**: When context > 128K, replace contents with paths

---

## CRITICAL: Understand Before Planning

**Before generating any plan, you MUST understand the problem domain.** Don't assume you know how to approach unfamiliar tasks.

### The Understanding Phase

When you receive a task prompt, BEFORE creating phases:

1. **Recognize what you don't know**
   - What domain is this? (IA software, medical records, financial systems?)
   - What terminology might be domain-specific?
   - What approaches exist for this type of problem?
   - What could go wrong if you guess?

2. **Research if the task is unfamiliar**
   - Use WebSearch to understand the domain
   - Look for best practices, common pitfalls, standard approaches
   - Document findings in `findings.md` BEFORE planning
   - If user says "research how to do this" - actually do research!

3. **Examine reference materials deeply**
   - Don't just count rows - understand what the data MEANS
   - Look for patterns, relationships, domain terminology
   - Sample actual values, not just column names
   - Ask: "What would a domain expert notice here?"

4. **Build understanding into the plan**
   - Include a "Domain Research" phase if unfamiliar territory
   - Plan for validation that checks SEMANTIC correctness, not just format
   - Identify what "success" looks like to a domain expert

### Anti-Pattern: Confident Ignorance

**DON'T:**
- Generate plans for unfamiliar domains without research
- Create algorithms based on surface-level pattern matching
- Assign high confidence to mappings/outputs you haven't validated semantically
- Skip the "understand" phase because it seems slow

**DO:**
- Admit when you don't understand a domain
- Research before committing to an approach
- Validate that your outputs make SENSE, not just that they have the right format
- Ask: "Would an expert in this domain approve this output?"

### Semantic Validation

When validating any output, ask:

| Question | Bad Answer | Good Answer |
|----------|------------|-------------|
| Does this mapping make sense? | "The names are similar" | "An address field should contain addresses, not percentages" |
| Is this approach correct? | "It produces output" | "This is how experts in this domain would solve it" |
| Are these results accurate? | "Confidence score is high" | "I spot-checked 5 items and they're semantically correct" |

### Example: Schema Mapping Task

**Wrong approach:**
1. Fuzzy match column names
2. Assign confidence based on string similarity
3. Generate output with "87% confidence"
4. Result: `Incident Address → INC_TASK_PERCENT` (garbage)

**Right approach:**
1. Research: "What is IAPro? What do its table/column names mean?"
2. Examine: Look at actual data patterns, not just names
3. Understand: "Address fields should contain street addresses"
4. Validate: "Does INC_TASK_PERCENT contain addresses? No - it's a percentage. Score: 0%"
5. Document: "There may not be an address field in this schema - flag for user"

---

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

## Quick Validation Phase

Before generating a full plan, optionally run a quick validation to test if a simple approach works.

### When Validation Runs

Validation runs when:
- `validation.enabled: true` in project.yaml
- Task doesn't contain skip keywords (architecture, security, complex)
- User prompt suggests a potentially simple task

### Validation Flow

```
1. Parse user prompt
2. Check for skip keywords → Skip validation if found
3. Run Quick Hypothesis Test:
   a. Extract 5-10 sample items (if applicable)
   b. Attempt simple direct approach
   c. Verify results
   d. Calculate confidence score
4. Decision:
   - Confidence >= threshold: Simplify plan (1-2 phases max)
   - Confidence < threshold: Proceed with full planning
```

### Validation Context Injection

```markdown
## Quick Validation Phase
You are testing whether a simple approach works for this task.

### Task
[User prompt]

### Instructions
1. Sample 5-10 items (if task involves multiple items)
2. Try the most straightforward approach first
3. Check if results are correct
4. Report confidence level (0-100%)

### Budget
- Max tokens: [from config]
- Max time: 5 minutes
- Do NOT generate a full plan yet

### Report Format
VALIDATION_RESULT:
- approach_tested: [brief description]
- sample_size: [N]
- success_rate: [X/N correct]
- confidence: [0-100]%
- blockers: [list any issues]
- recommendation: SIMPLE_PLAN | FULL_PLANNING
```

### Confidence Score Calculation

```
Base score = (successful_samples / total_samples) * 100

Adjustments:
- No errors encountered: +10%
- All edge cases handled: +10%
- Approach required workarounds: -20%
- External dependencies needed: -15%
- Ambiguous requirements detected: -25%

Final confidence = min(100, max(0, adjusted_score))
```

### Plan Simplification

When validation succeeds (confidence >= threshold):

**Original approach:**
- Phase 1: Research and analysis
- Phase 2: Design approach
- Phase 3: Implement core
- Phase 4: Testing
- Phase 5: Polish and deliver

**Simplified approach:**
- Phase 1: Execute validated approach
- Phase 2: Verify and deliver

### Skip Validation Cases

Never run validation for:
- Tasks with "architecture" keyword
- Tasks with "security" keyword
- Tasks with "complex" keyword
- Tasks explicitly requesting detailed planning
- Multi-system integrations
- Tasks involving data migrations

## Execution Flow

```
1. Read task-plan.md
   └─> If no phases: Run Quick Validation (if enabled) → Generate plan from prompt
   └─> If phases exist: Proceed to execution

2. For each phase:
   a. Determine complexity
   b. Select model
   c. **UPDATE STATUS.md** - Set current phase to "In Progress" BEFORE spawning agent
   d. Prepare context injection
   e. Spawn Task agent
   f. Agent executes
   g. Validate deliverables
   h. Update progress.md
   i. Mark phase complete in task-plan.md
   j. **UPDATE STATUS.md** - Mark phase complete, show next phase

3. After all phases:
   a. Run Quick Iteration (if enabled) → Self-check and fix errors
   b. Generate executive summary
   c. Extract lessons learned
   d. Archive if requested
```

## Quick Iteration Phase

After execution completes but before final delivery, optionally run a self-check to catch and fix obvious errors.

### When Iteration Runs

Iteration runs when:
- `iteration.enabled: true` in project.yaml
- Task doesn't contain skip keywords (draft, prototype, quick)
- All phases have completed successfully

### Iteration Flow

```
1. Sample outputs for review
2. Self-grade against success criteria:
   - Check output consistency
   - Verify completeness
   - Look for obvious errors
   - Validate format compliance
   - **SEMANTIC CHECK: Does this make sense to a domain expert?**
   - **SANITY CHECK: Would I be embarrassed to show this to the user?**
3. Calculate error rate from sample
4. Decision:
   - Error rate <= threshold: Proceed to delivery
   - Error rate > threshold: Run ONE focused correction pass
5. Deliver (no more iterations regardless of result)
```

### Iteration Context Injection

```markdown
## Quick Iteration Phase
You are self-checking outputs before final delivery.

### Task Summary
[Original goal from task-plan.md]

### Outputs to Check
[List of deliverables from completed phases]

### Instructions
1. Sample [N] items from outputs
2. Check each against these criteria:
   - Correctness: Does it match requirements?
   - Completeness: Are all parts present?
   - Consistency: Do patterns match across outputs?
   - Format: Does it follow expected structure?
3. Identify any errors found
4. Report error rate and patterns

### Budget
- Max tokens: [from config]
- This is a QUICK check, not a full review
- Focus on obvious/cheap success criteria

### Report Format
ITERATION_RESULT:
- sample_size: [N]
- errors_found: [count]
- error_rate: [X]%
- error_patterns: [list common issues]
- recommendation: DELIVER | FIX_AND_DELIVER

If FIX_AND_DELIVER:
- List specific fixes needed (max 3)
- Apply fixes within token budget
- Do NOT expand scope
```

### Error Rate Calculation

```
Error rate = errors_found / sample_size

Decision thresholds (from config):
- error_rate <= error_threshold: DELIVER as-is
- error_rate > error_threshold: Run correction pass

Correction pass rules:
- Focus only on error patterns found
- Stay within max_tokens budget
- Apply fixes, don't redesign
- ONE pass only (max_iterations: 1)
```

### Skip Iteration Cases

Never run iteration for:
- Tasks with "draft" keyword (expected to be rough)
- Tasks with "prototype" keyword (speed over polish)
- Tasks with "quick" keyword (minimal viable output)
- Tasks where user requests raw output
- Exploratory/research tasks

## Model Selection and Enforcement

### Model Tiers

| Tier | Model | Use For | Task Tool Parameter |
|------|-------|---------|---------------------|
| High | Opus | Architecture, security, complex debugging | `model: "opus"` |
| Medium | Sonnet | Standard implementation, testing, refactoring | `model: "sonnet"` |
| Low | Haiku | Docs, formatting, simple file ops, exploration | `model: "haiku"` |

### CRITICAL: How to Enforce Model Selection

When spawning Task agents, you MUST specify the model parameter:

```
Use the Task tool with:
- subagent_type: "general-purpose"
- model: "haiku" | "sonnet" | "opus"  <-- REQUIRED for cost optimization
- prompt: [context injection]
- description: [phase description]
```

**Example for a documentation phase (Low complexity):**
```
Task tool call:
  description: "Execute Phase 3: Documentation"
  subagent_type: "general-purpose"
  model: "haiku"
  prompt: "[full context injection]"
```

**Example for an implementation phase (Medium complexity):**
```
Task tool call:
  description: "Execute Phase 2: Implement API"
  subagent_type: "general-purpose"
  model: "sonnet"
  prompt: "[full context injection]"
```

**Example for an architecture phase (High complexity):**
```
Task tool call:
  description: "Execute Phase 1: Design Architecture"
  subagent_type: "general-purpose"
  model: "opus"
  prompt: "[full context injection]"
```

### Complexity Scoring Algorithm

When `task-plan.md` doesn't specify a model, calculate complexity:

#### Keyword Analysis (0-3 points each)
**High complexity keywords** (+3): architecture, design, complex, algorithm, security, debug, optimize
**Medium complexity keywords** (+2): implement, build, create, refactor, test, integrate
**Low complexity keywords** (+1): format, rename, move, document, simple, update, fix

#### File Count Factor
- 10+ files: +3 points
- 5-10 files: +2 points
- 2-5 files: +1 point
- 1 file: +0 points

#### Scoring Thresholds
- Score >= 6: **High** → Use `model: "opus"`
- Score >= 3: **Medium** → Use `model: "sonnet"`
- Score < 3: **Low** → Use `model: "haiku"`

### Explicit Override
If `task-plan.md` specifies `**Model**: [model]` for a phase, use that model.

### Model Selection for Special Tasks

| Task Type | Recommended Model |
|-----------|-------------------|
| Planning phase | Opus (main session default) |
| Exploration/research | Haiku |
| Code implementation | Sonnet |
| Test writing | Sonnet |
| Documentation | Haiku |
| Security review | Opus |
| Bug debugging | Opus |
| Simple file operations | Haiku |
| Refactoring | Sonnet |

### Tracking Model Usage

The cost report shows which model each subagent used. Review to ensure:
- Low-complexity tasks aren't using Opus (wasteful)
- High-complexity tasks aren't using Haiku (quality risk)

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

## ⚠️ MANDATORY: STATUS.md Updates

**The main session MUST update STATUS.md at these points:**

### Required Update Points

| When | What to Update |
|------|----------------|
| **Before** spawning phase agent | "Working on Phase X of Y: [Name]" |
| **After** phase completes | "Completed Phase X of Y", show next phase |
| After plan generation | "Plan Generated! Next: Execute the plan" |
| When waiting for user | "Waiting for your answer in Questions_For_You.md" |
| When project complete | Full executive summary |

### STATUS.md Format During Execution

```markdown
## 👉 WHAT TO DO NEXT

**Currently Running:** Phase 2 of 5 - Core Engine Development

**Progress:** I'm building the mapping engine. Check back in a few minutes!

---

## Quick Status

| Item | Status |
|------|--------|
| Phases Completed | 1 / 5 |
| Current Phase | Phase 2: Core Engine |
| Started At | 8:30 PM |
```

### Why This Is Critical

From the A/B testing, we found sessions that didn't update STATUS.md:
- Users couldn't tell if the system was hung
- Sessions ran 35+ minutes with no visibility
- Users had to Ctrl+C stop because they didn't know the state

STATUS.md is the user's window into what's happening. Update it FREQUENTLY.

### Checklist Before Spawning Each Phase Agent

- [ ] Did I update STATUS.md to show current phase?
- [ ] Does STATUS.md show "Phase X of Y" (not stale "Plan Generated")?
- [ ] Did I include an approximate timestamp?
- [ ] Did I explain what this phase will do?

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

## Delegation Health Metrics

The cost report tracks these metrics to help diagnose execution efficiency:

| Metric | Healthy Range | Warning Sign |
|--------|---------------|--------------|
| Delegation Ratio | 0-50% | >50% may indicate over-delegation |
| Subagents Spawned | 0-3 | >5 indicates poor task decomposition |
| Main Session Output | <50K tokens | >50K may need compaction |

**Note**: These are diagnostic tools, not targets. The goal is efficient execution, not hitting specific delegation numbers.
