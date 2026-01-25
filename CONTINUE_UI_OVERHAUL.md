# UI Overhaul Project - Continuation Prompt

Copy everything below this line into a new Claude Code session:

---

## Project: Simple Claude Conductor UI Overhaul

You are continuing work on a major UI overhaul for the Simple Claude Conductor project. This project helps non-technical users run Claude Code to build software projects.

### Use This Project's Own Workflow

This project has its own planning/execution system. **Use it to build itself.**

1. Read `CLAUDE.md` for workflow instructions
2. Read `docs/planning/UI_OVERHAUL_PLAN.md` for the detailed plan
3. Read `docs/planning/COMPREHENSIVE_PERMISSIONS.md` for the permissions strategy
4. Transfer the Phase 1 tasks into `docs/planning/task-plan.md`
5. Execute using the standard workflow: understand → plan → execute → validate

### What Was Decided (Previous Session)

| Decision | Resolution |
|----------|------------|
| **Architecture** | Portable Python bundle (~50MB) with Flask server |
| **Safety** | Comprehensive permissions in settings.local.json (no bypass needed) |
| **Archive** | Timestamped folders, no browsing - just notify user |
| **Prompt review** | Include "Review Prompt Quality" button |
| **Output location** | Inside project folder (`output/`) |

### Implementation Priority Order

1. **Phase 1: Infrastructure** - Portable Python + Flask server skeleton
2. **Phase 2: Archive/Reset** - Clean project lifecycle with guardrails
3. **Phase 3: Configuration Form** - Replace START_HERE.md editing
4. **Phase 4: Status Polling** - Progress visibility
5. **Phase 5: Question Integration** - Inline Q&A
6. **Phase 6: Polish** - Error handling, styling

### Key Files to Read First

```
docs/planning/UI_OVERHAUL_PLAN.md    # Complete plan with UI mockups, server code
docs/planning/COMPREHENSIVE_PERMISSIONS.md  # Full permissions enumeration
CLAUDE.md                            # Workflow instructions
project.yaml                         # Project configuration
.claude/settings.local.json          # Current permissions (to be expanded)
```

### The Problem We're Solving

Current workflow pain points for non-technical users:
- Must edit markdown files manually (START_HERE.md)
- Must remember terminal commands ("Generate a plan", "Execute the plan")
- No visibility into progress without opening STATUS.md
- No clean way to archive/reset between projects
- Confusing batch terminal interactions

### The Solution

A local web UI (`localhost:8080`) that:
- Guides users through 5 clear stages: Reset → Configure → Initialize → Generate → Execute
- Polls STATUS.md every 3 seconds for progress
- Shows inline forms for questions
- Archives old projects automatically
- Zero external installs (portable Python bundled)

### Your First Task

Start with Phase 1: Infrastructure & Portable Python Bundle

1. Research how to create/source a portable Python bundle for Windows
2. Set up the Flask server skeleton
3. Create START_CONDUCTOR.bat
4. Test that the browser opens and server runs
5. Expand settings.local.json with comprehensive permissions
6. Test that Claude can run a plan without permission interruptions

### Important Constraints

- Target users have NO coding experience
- Users should NEVER have to open a terminal manually
- Users should NEVER have to edit markdown files
- ~50MB download size is acceptable
- Windows-first (can consider Mac later)
- No Docker dependency

### When You Start

1. Run the prompt-understanding skill to confirm you understand the domain
2. Document your understanding in `docs/planning/findings.md`
3. Create phases in `docs/planning/task-plan.md` based on Phase 1 tasks
4. Update `STATUS.md` before starting work
5. Execute and validate each deliverable

Begin by reading the key files listed above, then proceed with the workflow.
