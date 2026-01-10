---
name: planning-with-files
description: Four-file pattern for complex multi-session projects. Use when: 5+ tasks, multi-session, high uncertainty, or cross-system changes.
---

# Planning With Files

A structured approach to managing complex, multi-session projects using four persistent files that maintain context across agent spawns and sessions.

## When to Use

Use this pattern when:
- **5+ implementation tasks** - Too many to track mentally
- **Work spans multiple sessions** - Need persistent context
- **High uncertainty** - Significant research required
- **Cross-system changes** - Touching multiple modules/services

Skip this pattern for:
- Quick bug fixes (< 30 min)
- Single-file changes
- Well-understood, isolated tasks

## The Four Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `task-plan.md` | Goal, phases, decisions, risks | Per major decision |
| `findings.md` | Research discoveries, patterns | Every 2 research ops (2-Action Rule) |
| `progress.md` | Session logs, completed work | End of each session/phase |
| `references.md` | Files found, external resources | When files discovered |

### task-plan.md
The master document. Contains:
- Goal statement (1-2 sentences)
- Success criteria (checkboxes)
- Phase breakdown with deliverables
- Decisions log with rationale
- Errors & blockers table
- Assumptions made

**Re-read this before major decisions.**

### findings.md
Research knowledge base. Contains:
- Summary of key discoveries
- Dated entries with source, finding, implication
- Patterns identified
- Questions answered

**Update every 2 research operations (2-Action Rule).**

### progress.md
Session history. Contains:
- Session entries with date, phase, model
- Completed tasks (checkboxes)
- Blockers encountered and resolutions
- Next steps for upcoming work

**Update at end of each session/phase.**

### references.md
File catalog. Contains:
- Source code files with purpose
- Documentation files
- Configuration files
- External resources

**Add files immediately when discovered via MCP or search.**

## Key Rules

### Rule 1: Re-Read Before Deciding
Before any major decision, re-read the relevant sections of `task-plan.md`. Don't rely on memory.

### Rule 2: 2-Action Rule
Update `findings.md` every 2 research operations:
- Grep, Glob, Read, WebSearch, WebFetch count as research
- Write brief entry: Source → Finding → Implication
- Don't wait until end of session

### Rule 3: 3-Strike Protocol
When blocked:
1. Try obvious approach
2. Try alternative approach
3. Try creative workaround
4. Escalate - document in task-plan.md Errors table

### Rule 4: MCP-First
Before Grep/Glob:
1. Try MCP tools first (if available)
2. Add found files to `references.md`
3. Fall back to Grep/Glob only if needed

### Rule 5: Phase Completion
Mark phase complete only when:
- All deliverables checked off
- Progress entry written
- Next phase ready to start

## Initialization

Run the initialization script to create empty planning files:

```bash
.claude/skills/planning-with-files/scripts/init-planning.sh "Project Name"
```

Or initialize manually by copying templates from:
```
.claude/skills/planning-with-files/templates/
```

## File Locations

Planning files live in: `docs/planning/`

```
docs/planning/
├── README.md          # Overview of current project
├── task-plan.md       # Master plan
├── findings.md        # Research findings
├── progress.md        # Session history
├── references.md      # File catalog
├── reports/           # Generated reports
└── archive/           # Completed project archives
```

## Integration with Project Executor

This skill provides the foundation for the `project-executor` skill:
1. Planning files must be initialized first
2. `task-plan.md` must have phases defined
3. Executor reads phases and spawns agents
4. Agents update planning files as they work
5. Files persist context across agent spawns
