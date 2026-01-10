# Claude Project Executor

This folder contains the Claude Project Executor template - a system for intelligent plan execution with automatic model selection and fresh agents per phase.

## Quick Reference

### Key Files
- `instructions.md` - Core workflow principles (Stub→Review→Implement, 2-Action Rule, etc.)
- `workflow-guide.md` - Agent usage patterns and context injection
- `settings.local.json` - Hook configurations

### Skills
- `skills/planning-with-files/` - Four-file planning pattern
- `skills/project-executor/` - Phase execution orchestration

### Hooks
- `hooks/mcp-reminder.sh` - File discovery reminder
- `hooks/branch-protection.sh` - Git safety
- `hooks/file-guard.sh` - Organization enforcement
- `hooks/findings-reminder.sh` - 2-Action Rule enforcement

## Getting Started

1. Run `../project-init.sh` to initialize the project
2. Edit `../project.yaml` to configure settings
3. Provide Claude with a prompt describing your goal
4. Claude generates a plan, asks questions, then executes

## Core Principles

1. **Fresh Agents, Persistent Files** - Spawn new agents per phase; files carry context
2. **2-Action Rule** - Update findings.md every 2 research operations
3. **MCP-First** - Try MCP tools before Grep/Glob
4. **Stub → Review → Implement** - Structure before code
5. **3-Strike Protocol** - Try 3 approaches before escalating
