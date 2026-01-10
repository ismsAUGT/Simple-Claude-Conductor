# Workflow Guide: Agent Patterns

This guide describes how to use Task agents effectively for project execution.

## Agent Types and When to Use Them

### Explore Agent (subagent_type: Explore)
**When**: Finding files, understanding codebase structure, researching patterns
**Model**: Usually haiku (fast exploration)
```
Example prompt: "Find all files related to user authentication. Add results to references.md."
```

### General-Purpose Agent (subagent_type: general-purpose)
**When**: Multi-step implementation tasks
**Model**: Based on complexity (haiku/sonnet/opus)
```
Example prompt: "Implement the User model with fields: id, email, passwordHash, createdAt. Update progress.md when done."
```

### Plan Agent (subagent_type: Plan)
**When**: Designing architecture, planning complex implementations
**Model**: Usually opus (high-quality reasoning)
```
Example prompt: "Design the authentication system architecture. Document decisions in task-plan.md."
```

## Context Injection Pattern

When spawning a phase agent, inject this context:

```markdown
## Context Injection
You are executing Phase [N]: [Name]

### Goal
[From task-plan.md - the overall project goal]

### Phase Requirements
[From task-plan.md - this phase's deliverables]

### Relevant Findings
[From findings.md - entries relevant to this phase]

### Key Files
[From references.md - files this phase will touch]

### Previous Progress
[From progress.md - last 2 session summaries]

### Instructions
1. Complete the phase deliverables
2. Update findings.md for any research (2-Action Rule)
3. Update progress.md when phase is complete
4. Report any blockers immediately
```

## Model Selection Guidelines

| Complexity | Model | Indicators |
|------------|-------|------------|
| Low | haiku | formatting, docs, simple file ops, renaming |
| Medium | sonnet | standard implementation, CRUD, testing, refactoring |
| High | opus | architecture, security, complex algorithms, debugging |

### Complexity Scoring
- High keywords: architecture, design, complex, algorithm, security
- Medium keywords: implement, build, create, refactor, test
- Low keywords: format, rename, move, document, simple
- Many files (10+) → increase complexity
- Explicit override in task-plan.md takes precedence

## Phase Execution Flow

```
For each phase in task-plan.md:
  1. Extract phase requirements
  2. Determine complexity → select model
  3. Gather context (findings, references, last 2 progress entries)
  4. Spawn fresh Task agent with context injection
  5. Agent executes phase
  6. Validate deliverables against criteria
  7. Update phase status in task-plan.md
  8. Continue to next phase
```

## Recovery Pattern

If execution is interrupted:
1. Read `task-plan.md` → Find current phase status
2. Read `progress.md` → Find last completed work
3. Resume from interruption point
4. No context is lost because files persist

## Error Handling

When an agent encounters errors:
1. Log error in `task-plan.md` Errors table
2. Attempt 3-Strike Protocol
3. If unresolved, mark phase as blocked
4. Report to orchestrator for human intervention

## Best Practices

1. **One phase at a time** - Don't try to parallelize phases
2. **Fresh agent per phase** - Never reuse agents across phases
3. **Context is minimal** - Only inject relevant context, not entire history
4. **Files are truth** - Always defer to file contents over memory
5. **Update immediately** - Don't batch updates to planning files
