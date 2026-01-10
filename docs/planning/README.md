# Planning Files

This folder contains the persistent planning files for the Claude Project Executor.

## Files

| File | Purpose | When to Update |
|------|---------|----------------|
| **task-plan.md** | Master plan with goal, phases, decisions | When making major decisions or completing phases |
| **findings.md** | Research discoveries and patterns | Every 2 research operations (2-Action Rule) |
| **progress.md** | Session history and progress tracking | End of each session or phase |
| **references.md** | Catalog of files discovered | When new files are found via MCP or search |

## Subfolders

- **reports/** - Generated summary reports and execution logs
- **archive/** - Completed project archives for reference

## Key Rules

### 1. Re-Read Before Deciding
Before major decisions, re-read the relevant sections of `task-plan.md`. Don't rely on memory.

### 2. 2-Action Rule
Update `findings.md` every 2 research operations:
- Research operations: Grep, Glob, Read, WebSearch, WebFetch
- Write: Source → Finding → Implication

### 3. 3-Strike Protocol
When blocked:
1. Try obvious approach
2. Try alternative approach
3. Try creative workaround
4. Escalate to task-plan.md Errors table

### 4. MCP-First
Before Grep/Glob, try MCP tools first. Add found files to `references.md`.

## Getting Started

If files are empty, provide Claude with a prompt like:
- "Build a REST API for user management"
- "Create a React dashboard with data visualization"

Claude will generate a structured plan and populate these files.

## File Templates

Templates are located in:
```
.claude/skills/planning-with-files/templates/
```

To reinitialize:
```bash
bash .claude/skills/planning-with-files/scripts/init-planning.sh "Project Name"
```
