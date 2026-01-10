# CLAUDE.md

This project uses **Simple Claude Conductor** for intelligent plan execution.

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

**CRITICAL: Always update the "👉 WHAT TO DO NEXT" section at the top** to guide the user to their next action:

Keep it simple and readable for non-technical users.

**Example "WHAT TO DO NEXT" messages by stage:**

| Stage | What To Show |
|-------|-------------|
| Plan generated | "Your Next Step: Type 'Execute the plan' to start building" |
| Mid-execution | "Your Next Step: I'm working on Phase X of Y. Check back for updates!" |
| Waiting for answers | "Your Next Step: Open Questions_For_You.md and answer my questions, then press Enter" |
| Execution complete | "Your Next Step: Check the `output/` folder for your generated files!" |
| Error/blocked | "Your Next Step: [Specific action needed to unblock]" |

The goal is that a user can open STATUS.md at any time and immediately know what to do.

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
