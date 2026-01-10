# CLAUDE.md

This project uses **Simple Claude Conductor** for intelligent plan execution.

## Important: User Communication Files

This project is designed for non-technical users. Use these files to communicate:

### Questions_For_You.md
**When you have questions for the user**, write them to this file instead of just asking in the terminal.

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

After writing questions:
1. Tell the user: "I've written some questions to Questions_For_You.md - please open that file and answer them."
2. Tell them to press Enter when done, or press Enter without answering to let you make assumptions
3. Read their answers from the file and proceed

### STATUS.md
**Update this file** whenever you complete significant work:
- After generating a plan
- After completing a phase
- When changing project status
- With a brief progress summary

Keep it simple and readable for non-technical users.

## Quick Start Workflow

1. User provides a description (already in `docs/planning/task-plan.md` Goal section)
2. Generate a plan with phases
3. Ask clarifying questions via `Questions_For_You.md` (if `interrupt_for_questions: true`)
4. Execute phases sequentially
5. Update `STATUS.md` after each phase
6. Generate executive summary when complete

## Configuration

Settings are in `project.yaml`:
- **default_model**: haiku | sonnet | opus
- **interrupt_for_questions**: true = ask questions first, false = make assumptions
- **bypass_permissions**: true = skip confirmations
- **test_first**: true = TDD mode
- **quality_gates**: run tests/typecheck/lint before completing phases

## Key Commands (What Users Might Say)

| User Says | What To Do |
|-----------|------------|
| "Generate a plan" | Read goal from task-plan.md, create phases |
| "Execute the plan" | Start or continue phase execution |
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

Keep the status file updated with a simple format:

```markdown
## Quick Status

| Item | Status |
|------|--------|
| Plan Generated | Yes/No |
| Current Phase | Phase X of Y |
| Phases Completed | N / Total |

## What's Happening Now
[Brief description of current work]

## Recent Progress
- [x] Completed item 1
- [x] Completed item 2
- [ ] Working on item 3
```

## Recovery

If a session is interrupted:
1. Read `task-plan.md` to find current phase
2. Read `progress.md` to find last completed work
3. Resume from interruption point
4. Update STATUS.md with current state
