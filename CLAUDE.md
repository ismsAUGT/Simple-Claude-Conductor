# CLAUDE.md

This project uses **Simple Claude Conductor** for intelligent plan execution.

## CRITICAL: Understand Before Doing

**Before planning or executing ANY unfamiliar task:**

1. **Admit what you don't know** - What domain is this? What would an expert know?
2. **Research first** - Use WebSearch, read reference materials deeply, understand terminology
3. **Document understanding** - Fill out the "Domain Understanding" section in findings.md
4. **Validate semantically** - Don't just check format, check if outputs MAKE SENSE

**Anti-pattern to avoid:** Generating confident-looking outputs for domains you don't understand. High confidence scores mean nothing if the underlying logic is wrong.

**Ask yourself:** "Would a domain expert approve this, or would they immediately spot problems?"

## Important: User Communication Files

This project is designed for non-technical users. Use these files to communicate:

### File_References_For_Your_Project/
**Check this folder at the start of planning** to see if the user has provided reference materials:
- Sample files to mimic
- Documentation to reference
- Data files to process
- Screenshots of desired layouts
- Code examples to replicate
- Templates to use

If files are present, read them and incorporate them into your understanding of the project goals. These files provide valuable context beyond what's in START_HERE.md.

### Questions_For_You.md
**When you have questions for the user**, write them to this file.

**Two types of questions:**

1. **Planning Questions** (DURING plan generation):
   - Asked automatically if `allowPlanningQuestions: true`
   - UI will detect them and pause for user input
   - Format: `**Your Answer:** _____` (3+ underscores)
   - See "Planning Questions Workflow" section for details

2. **Execution Questions** (DURING execution):
   - Asked when you encounter ambiguity mid-execution
   - Write questions and tell the user to answer them
   - After they answer, read the file and proceed

Format questions like this:
```markdown
## Questions

### Question 1: [Topic]
[Your question here]

**Your Answer:** _____

### Question 2: [Topic]
[Your question here]

**Your Answer:** _____
```

For execution questions, tell the user:
1. "I've written some questions to Questions_For_You.md - please open that file and answer them."
2. "Press Enter when done, or press Enter without answering to let me make assumptions"
3. Read their answers from the file and proceed

### STATUS.md
**Update this file FREQUENTLY** - users check it to know if things are working:
- After generating a plan
- **BEFORE starting each phase** (mark it "In Progress")
- After completing each phase
- Every few minutes during long operations
- When errors occur

**CRITICAL: Always update the "👉 WHAT TO DO NEXT" section at the top** to guide the user to their next action:

Keep it simple and readable for non-technical users.

**Example "WHAT TO DO NEXT" messages by stage:**

| Stage | What To Show |
|-------|-------------|
| Planning | "Status: Generating plan... (started at HH:MM)" |
| Plan generated | "Your Next Step: Type 'Execute the plan' to start building" |
| Starting phase | "Status: Starting Phase X of Y: [Name]... (started at HH:MM)" |
| Mid-execution | "Status: Working on Phase X of Y. Check back for updates!" |
| Waiting for answers | "Your Next Step: Open Questions_For_You.md and answer my questions, then press Enter" |
| Execution complete | "Your Next Step: Check the `output/` folder for your generated files!" |
| Error/blocked | "Your Next Step: [Specific action needed to unblock]" |

**Include timestamps** so users can tell if progress is being made.

The goal is that a user can open STATUS.md at any time and immediately know:
1. What is currently happening
2. When it started
3. Whether it's stuck or progressing

## Quick Start Workflow

1. User provides a description (already in `docs/planning/task-plan.md` Goal section)
2. **Quick Validation** (if `validation.enabled: true` in project.yaml):
   - Test simple approach on 5-10 sample items
   - If confidence >= 80%: Use simplified 1-2 phase plan
   - If confidence < 80%: Proceed with full planning
   - Skipped for tasks with "architecture", "security", or "complex" keywords
3. Generate a plan with phases (complexity informed by validation)
4. Ask clarifying questions via `Questions_For_You.md` (if `interrupt_for_questions: true`)
5. Execute phases sequentially
6. Update `STATUS.md` after each phase
7. **Quick Iteration** (if `iteration.enabled: true` in project.yaml):
   - Self-check sample of outputs for errors
   - If error rate > 10%: Run ONE focused correction pass (budget-capped)
   - Skipped for tasks with "draft", "prototype", or "quick" keywords
8. Generate executive summary when complete

## Planning Questions Workflow

**NEW FEATURE:** The conductor supports asking clarifying questions during plan generation.

### When Planning Questions Are Used

After you generate a plan, if **both** conditions are met:
1. `allowPlanningQuestions: true` in `config/project-config.json` (default: true)
2. You wrote questions to `Questions_For_You.md` with unanswered format

Then the UI will:
- Transition to `plan_questions` state
- Display a card with "Claude Has Questions About Your Project"
- Let the user answer, skip, or defer questions

### How to Write Planning Questions

**Format Requirements:**
- Write questions to `Questions_For_You.md` during plan generation
- Use the exact format: `**Your Answer:** _____` (with at least 3 underscores) for blank answers
- This format signals to the system that questions are unanswered

**Example:**
```markdown
## Questions

### Question 1: Database Choice
Which database do you want to use for this project?

**Your Answer:** _____

### Question 2: Authentication Method
Do you want to use OAuth, JWT, or session-based authentication?

**Your Answer:** _____
```

### When to Ask Planning Questions

**DO ask questions when:**
- Requirements are genuinely ambiguous (e.g., "add authentication" - what type?)
- Multiple valid approaches exist and user preference matters (e.g., database choice, UI framework)
- Scope is unclear (e.g., "improve performance" - which parts?)
- Technology stack decisions need user input (e.g., REST vs GraphQL)

**DON'T ask questions when:**
- The answer is clear from context or reference files
- You can make a reasonable assumption based on existing codebase patterns
- The question is about implementation details rather than requirements
- You're asking just to be cautious (trust your expertise!)

**Quality Guidelines:**
- Limit to 3-5 most important questions
- Make each question clear and specific
- Offer context or trade-offs where helpful
- Focus on decisions that significantly impact the plan

### What Happens After Questions

**If user answers:**
- You receive a prompt: "Review answers in Questions_For_You.md and refine the plan"
- Update `task-plan.md` based on their input
- Adjust phases, success criteria, or approach as needed
- The system will detect the refined plan and transition to `planned` state

**If user skips:**
- You receive a prompt: "Finalize plan using your best judgment"
- Proceed with reasonable defaults
- Document your assumptions in `findings.md`
- The system will transition to `planned` state

### State Flow

```
planning → (questions detected) → plan_questions → (user answers/skips) → planning → planned
planning → (no questions) → planned
```

**Important:** The questions feature is opt-in. If `allowPlanningQuestions: false`, the system will skip the `plan_questions` state even if you write questions.

## Critical Workflow Skills

Simple Claude Conductor v4 uses three workflow skills to ensure quality. These skills are NOT optional.

### Skill 1: prompt-understanding (BEFORE Planning)

**ALWAYS** run this skill before generating any plan phases.

**What it does:**
1. Analyzes the user's request to understand the actual "job to be done"
2. Assesses your familiarity with the domain (High / Medium / Low)
3. Researches unfamiliar domains (WebSearch if needed)
4. Asks clarifying questions or documents assumptions
5. Documents understanding in findings.md

**Enforcement:**
- DO NOT generate phases in task-plan.md until findings.md has a populated "Domain Understanding" section
- The pre-planning-check hook will block planning if this section is missing

**Location:** `.claude/skills/prompt-understanding/SKILL.md`

---

### Skill 2: task-decomposition (DURING Planning)

**ALWAYS** define success criteria for each phase when planning.

**What it does:**
1. Breaks work into logical phases
2. Defines specific, verifiable success criteria for each phase
3. Documents dependencies between phases

**Enforcement:**
- Every phase MUST have success criteria
- Criteria must be specific (not "works correctly" or "is complete")
- Criteria must be verifiable (can be objectively checked)

**Bad example:**
```markdown
**Success Criteria:**
- [ ] Phase is complete
- [ ] Code works
```

**Good example:**
```markdown
**Success Criteria:**
- [ ] Script processes all rows from input.csv (verified by row count in log)
- [ ] Output contains columns: id, name, status (verified by checking output headers)
- [ ] No errors in execution log
```

**Location:** `.claude/skills/task-decomposition/SKILL.md`

---

### Skill 3: output-validation (AFTER Execution)

**ALWAYS** run this skill before marking any phase complete.

**What it does:**
1. Checks each success criterion with specific evidence
2. Spot-checks 5-10 sample outputs for semantic correctness
3. Requires justification (explain WHY each output is correct)
4. Flags items that cannot be justified
5. Documents validation results in progress.md

**Enforcement:**
- DO NOT mark a phase complete without documented validation in progress.md
- The phase-completion-check hook will block completion if validation is missing

**Confidence rules:**
- Only claim high confidence (>80%) if you can cite specific evidence
- If justification is weak, cap confidence and flag for review
- Better to flag and be wrong than miss real issues

**Location:** `.claude/skills/output-validation/SKILL.md`

---

### Workflow Summary

```
1. User provides request
2. RUN prompt-understanding skill
   → Document understanding in findings.md
3. RUN task-decomposition skill
   → Create phases with success criteria in task-plan.md
4. Execute each phase
5. RUN output-validation skill for each phase
   → Document validation in progress.md
6. Mark phase complete only after validation passes
7. Repeat 4-6 for each phase
8. Generate executive summary when all phases complete
```

### What Happens If You Skip Skills

- **Skip prompt-understanding:** Pre-planning hook blocks plan generation
- **Skip success criteria:** Validation has nothing to check, quality suffers
- **Skip output-validation:** Phase-completion hook blocks marking complete

The skills exist because v3 produced incorrect outputs by skipping understanding and validation. Do not repeat this mistake.

## Configuration

Settings are in `project.yaml`:
- **default_model**: haiku | sonnet | opus
- **interrupt_for_questions**: true = ask questions first, false = make assumptions
- **bypass_permissions**: true = skip confirmations
- **validation.enabled**: true = run quick validation before planning
- **validation.confidence_threshold**: 0.8 = 80% confidence needed to simplify plan
- **iteration.enabled**: true = run quick iteration after execution
- **iteration.error_threshold**: 0.1 = run correction if >10% errors in sample
- **test_first**: true = TDD mode
- **quality_gates**: run tests/typecheck/lint before completing phases

## Execution Strategy: Stay In-Session by Default

**Default behavior**: Work in the main session. Use subagents sparingly.

### Simple Decision Rule

Ask: **"Will a subagent need the same large files I already have cached?"**
- **YES** → Stay in-session (cache reuse is valuable)
- **NO** → Consider delegating

### When to Stay In-Session (Default)

- Implementation/coding tasks
- All phases need same reference files (>50K tokens shared)
- Sequential dependencies between phases

### When to Delegate

- Pure research with no shared files
- Validation/testing (discrete, bounded tasks)
- Independent exploration directions (max 2-3 agents)

### Compaction (When context > 128K)

1. Replace file contents with paths
2. Summarize old outputs
3. Keep last 3-5 turns in full

### Model Selection

| Task Type | Model |
|-----------|-------|
| Docs, exploration | haiku |
| Implementation | sonnet |
| Architecture, security | opus |

Settings in `project.yaml`:
- `delegation_mode: "conservative"` (default) - Stay in-session
- `delegation_mode: "parallel"` - Spawn agents per phase

## Key Commands (What Users Might Say)

| User Says | What To Do |
|-----------|------------|
| "Generate a plan" | Read goal from task-plan.md, create phases |
| "Execute the plan" | Start or continue phase execution |
| "Validate first" | Run quick validation before planning |
| "Show progress" | Summarize STATUS.md and current state |
| "Continue" | Resume from last completed work |
| "Summarize" | Generate executive summary |

## Planning Files

All planning context lives in `docs/planning/`:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `task-plan.md` | Goal, phases, decisions | Major decisions |
| `findings.md` | Research discoveries | Every 2 research ops |
| `progress.md` | Session history | End of session/phase |
| `references.md` | File catalog | When files found |

## Core Principles

1. **Fresh Agents, Persistent Files** - Each phase gets a fresh agent; files carry context
2. **2-Action Rule** - Update findings.md every 2 research operations
3. **Stub → Review → Implement** - Structure before code
4. **3-Strike Protocol** - Try 3 approaches before escalating
5. **User-Friendly Communication** - Use Questions_For_You.md and STATUS.md

## Model Selection

| Complexity | Model | When Used |
|------------|-------|-----------|
| Low | Haiku | Docs, formatting, simple file ops |
| Medium | Sonnet | Standard implementation, testing |
| High | Opus | Architecture, security, debugging |

## Quality Gates

If enabled in `project.yaml`:
1. Complete phase implementation
2. Run enabled quality checks (tests/typecheck/lint)
3. Fix any failures before marking complete

## Updating STATUS.md

**ALWAYS start with the "WHAT TO DO NEXT" section** - this is the most important part for users!

Keep the status file updated with this format:

```markdown
# Project Status: [Project Name]

**Last Updated**: [Date]

---

## 👉 WHAT TO DO NEXT

**[Current status in plain English]**

**Your Next Step:** [Specific action for user - be very clear!]

---

## Quick Status

| Item | Status |
|------|--------|
| Plan Generated | Yes/No |
| Current Phase | Phase X of Y |
| Phases Completed | N / Total |

---

## Recent Progress

- [x] Completed item 1
- [x] Completed item 2
- [ ] Working on item 3

---

## Progress Log

[Detailed updates - Claude adds here as work progresses]
```

**Remember**: The "WHAT TO DO NEXT" section should be updated EVERY time you update STATUS.md. Users should never have to guess what to do next!

## Anti-Loop Protection

**CRITICAL**: Do NOT regenerate the plan if it already exists and has phases.

### Signs You're in a Loop
- Repeating the same action (e.g., "Creating plan..." multiple times)
- STATUS.md not updating for >5 minutes
- task-plan.md shows phases but they stay "Not Started"

### If Plan Exists, Execute It
1. Read task-plan.md
2. If phases are defined → Go straight to execution
3. Do NOT regenerate unless user explicitly asks

### Execution Timeout Guidance
- Planning phase: Should complete in <5 minutes
- Each execution phase: Should show progress within 10 minutes
- If no STATUS.md update for 15+ minutes: Something may be stuck

## Execution Feedback

During execution, provide feedback to help users understand value:

### Progress Updates
After each phase, tell the user:
- "Completed Phase X of Y: [Phase Name]"
- "Created N files in [location]"
- "Next: [brief description of next phase]"

### Context Management
When spawning fresh agents or switching models, tell the user:
- "Starting fresh agent for Phase X (prevents context bloat)"
- "Using [Model] for this phase (optimized for [reason])"

### At Completion
Update STATUS.md with a comprehensive summary including:
- What was built (with file locations)
- Key metrics (files created, confidence levels, etc.)
- Clear next steps for the user

## Executive Summary

When the project completes, STATUS.md should serve as the executive summary:

```markdown
## Quick Status
| Item | Status |
|------|--------|
| Project Initialized | Yes |
| Plan Generated | Yes |
| Current Phase | Complete |
| Phases Completed | X / X |

## What Was Built
[Brief description of the deliverable]

## Output Files Generated
| File | Description |
|------|-------------|
| output/file1 | What it contains |
| output/file2 | What it contains |

## Results / Metrics
| Metric | Value |
|--------|-------|
| [Key metric] | [Value] |

## Next Steps for You
1. [Action item]
2. [Action item]
```

## Recovery

If a session is interrupted:
1. Read `task-plan.md` to find current phase
2. Read `progress.md` to find last completed work
3. Resume from interruption point
4. Update STATUS.md with current state

## Safety Gates

The project includes safety limits (in project.yaml):
- `max_files_per_phase: 20` - Don't create too many files at once
- `max_iterations_per_task: 5` - Avoid infinite loops
- `stop_on_repeated_errors: 3` - Stop if same error 3 times
- `max_total_files: 100` - Cap total files created

If hitting limits, pause and ask user for guidance.

## Archive Folder

The `archive/` folder contains old project files from previous runs.

**IMPORTANT - Do NOT access archive files:**
- Do NOT read files from `archive/` - they are historical only
- Do NOT include `archive/` in Grep/Glob searches
- Do NOT reference archived files in your responses
- This saves context and avoids confusion with old project files

When searching the codebase, always exclude archive:
- Grep: Use path that doesn't include archive, or mentally skip archive results
- Glob: Don't use patterns that match `archive/**`

The archive folder exists so users can review their old projects, but Claude should treat it as if it doesn't exist.

---

## Cost Report Generation

**At the end of each session**, generate a cost report by running:
```bash
python scripts/generate_cost_report.py .
```

This creates `output/cost_report.md` with:
- Token usage breakdown (input, output, cache read/write)
- Estimated API cost (for reference)
- Subagent usage
- Cache efficiency metrics

Include key metrics in the executive summary (STATUS.md):
```markdown
## Session Metrics
| Metric | Value |
|--------|-------|
| Est. API Cost | $X.XX |
| Cache Efficiency | X% |
| Subagents Used | N |
| Context Savings | ~$X.XX |
```
