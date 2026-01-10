# CLAUDE.md

This project uses **Claude Project Executor** for intelligent plan execution.

## Quick Start

1. Describe what you want to build
2. Claude generates a plan and asks clarifying questions
3. Approve the plan to begin execution
4. Claude executes phases with optimal model selection
5. Receive an executive summary when complete

## Configuration

Edit `project.yaml` to customize:
- **default_model**: haiku | sonnet | opus
- **interrupt_for_questions**: true = ask before proceeding, false = use best guesses
- **bypass_permissions**: true = skip confirmations during execution

## Key Commands

| Command | Description |
|---------|-------------|
| "Generate a plan for [description]" | Start planning phase |
| "Execute the plan" | Begin phase execution |
| "Show progress" | View current status |
| "Continue from where we left off" | Resume interrupted work |
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
5. **MCP-First** - Use MCP tools before Grep/Glob for file discovery

## Model Selection

| Complexity | Model | When Used |
|------------|-------|-----------|
| Low | Haiku | Docs, formatting, simple file ops |
| Medium | Sonnet | Standard implementation, testing |
| High | Opus | Architecture, security, debugging |

## Documentation

- `.claude/README.md` - System overview
- `.claude/instructions.md` - Core workflow principles
- `.claude/workflow-guide.md` - Agent patterns
- `.claude/skills/planning-with-files/SKILL.md` - Planning pattern details
- `.claude/skills/project-executor/SKILL.md` - Execution orchestration

## Recovery

If a session is interrupted:
1. Claude reads `task-plan.md` to find current phase
2. Claude reads `progress.md` to find last completed work
3. Claude resumes from interruption point
4. No context is lost - files are the source of truth
