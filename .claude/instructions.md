# Core Workflow Principles

These principles govern all work in this project. Re-read before major decisions.

## 1. Stub → Review → Implement

Never write complete code in one pass:
1. **Stub**: Create structure with placeholders
2. **Review**: Verify structure meets requirements
3. **Implement**: Fill in implementation details

This prevents wasted work from wrong assumptions.

## 2. MCP-First for File Discovery

Before using Grep/Glob to find files:
1. Try MCP tools first (if available)
2. Add discovered files to `docs/planning/references.md`
3. Only fall back to Grep/Glob if MCP unavailable

This ensures consistent file tracking.

## 3. 2-Action Rule

Update `docs/planning/findings.md` every 2 research operations:
- Research operations: Grep, Glob, Read, WebSearch, WebFetch
- Write a brief entry with: Source, Finding, Implication
- Don't wait until the end - context may be lost

This prevents knowledge loss in long sessions.

## 4. 3-Strike Protocol

When encountering blockers:
1. **Strike 1**: Try the obvious approach
2. **Strike 2**: Try an alternative approach
3. **Strike 3**: Try a creative workaround
4. **Escalate**: Document in task-plan.md Errors table, ask for help

Don't waste time on dead ends.

## 5. Fresh Agents, Persistent Files

- Each phase gets a fresh Task agent
- Agents don't share memory directly
- Files (`task-plan.md`, `findings.md`, etc.) carry context between agents
- This prevents context degradation over long projects

## 6. Minimal Implementation

Only implement what's explicitly requested:
- No speculative features
- No "nice to have" additions
- No preemptive abstractions
- Keep solutions as simple as possible

## 7. Continuous Documentation

Update planning files as work progresses:
- `task-plan.md` - Major decisions, phase status
- `findings.md` - Research discoveries (2-Action Rule)
- `progress.md` - End of each session/phase
- `references.md` - New files discovered

Future sessions depend on this documentation.

## 8. Re-Read Before Deciding

Before any major decision:
1. Re-read relevant sections of `task-plan.md`
2. Check `findings.md` for related discoveries
3. Review `references.md` for relevant files
4. Then proceed with the decision

Don't rely on memory - files are the source of truth.
