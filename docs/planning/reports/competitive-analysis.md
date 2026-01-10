# Competitive Analysis: Simple Claude Conductor

**Date**: 2025-01-10

## Executive Summary

Simple Claude Conductor occupies a middle ground in the Claude orchestration ecosystem - more structured than basic setups, simpler than full multi-agent frameworks. The key differentiators are **simplicity** and the **four-file planning pattern**.

---

## Project Summaries

### 1. Ralph (snarktank/ralph)
**Focus**: Autonomous iterative execution with PRD-driven development

- Runs in a loop until all PRD items complete
- Fresh Amp instance each iteration
- Uses git commits + `prd.json` for state
- Quality gates (typecheck, tests) before commits
- Auto-archives previous runs

**Complexity**: Medium | **Multi-agent**: No (sequential) | **Stars**: ~New

---

### 2. Gas Town (steveyegge/gastown)
**Focus**: Multi-agent orchestration at scale (20-30 agents)

- Go-based workspace manager
- Coordinates multiple AI agents simultaneously
- Git worktree-based persistence ("Hooks")
- Built-in mailboxes for agent communication
- Real-time dashboards
- "The Mayor" AI coordinator pattern

**Complexity**: High | **Multi-agent**: Yes (parallel) | **Author**: Steve Yegge

---

### 3. Planning With Files (OthmanAdi/planning-with-files)
**Focus**: Three-file planning pattern (our direct inspiration)

- task_plan.md, findings.md, progress.md
- PreToolUse hook reads plan before actions
- 2-Action Rule enforcement
- Cross-platform (Claude Code, Cursor)

**Complexity**: Low | **Multi-agent**: No | **Note**: We extended this to four files

---

### 4. Superpowers (obra/superpowers)
**Focus**: Disciplined software engineering workflows

- Design refinement before coding
- Test-first development (RED-GREEN-REFACTOR)
- Subagent-driven execution with code review checkpoints
- Git worktrees for isolated branches
- Granular task breakdown (2-5 min each)

**Complexity**: Medium-High | **Multi-agent**: Yes (subagents) | **Stars**: Popular

---

### 5. Vibe Kanban (BloopAI/vibe-kanban)
**Focus**: Visual task management UI for multiple agents

- Web-based kanban board
- Supports Claude Code, Gemini CLI, Codex
- Parallel or sequential agent orchestration
- Centralized MCP configuration
- Remote SSH access support

**Complexity**: Medium | **Multi-agent**: Yes | **Type**: Web UI

---

### 6. Claude-Mem (thedotmack/claude-mem)
**Focus**: Persistent memory across sessions

- Automatic context capture via hooks
- AI-compressed observations
- Vector search (Chroma) for retrieval
- Progressive disclosure (3-layer memory)
- Web interface for memory viewer
- Privacy controls (`<private>` tags)

**Complexity**: Medium | **Multi-agent**: No | **Focus**: Memory only

---

### 7. Anthropic Skills (anthropics/skills)
**Focus**: Official skill library and specification

- Skill folder structure standard
- Document skills (PDF, DOCX, PPTX, XLSX)
- Creative, technical, enterprise categories
- Works with Claude Code, Claude.ai, API

**Complexity**: Reference | **Multi-agent**: N/A | **Stars**: 37k

---

### 8. Claude Code Showcase (ChrisWiles/claude-code-showcase)
**Focus**: Comprehensive configuration template

- CLAUDE.md patterns
- Intelligent skill suggestions via hooks
- Domain-specific skills (React, GraphQL, testing)
- GitHub Actions for automated reviews
- JIRA/Linear integration
- MCP server examples

**Complexity**: Medium | **Multi-agent**: No | **Type**: Template/Examples

---

## Feature Comparison

| Feature | Simple Claude Conductor | Ralph | Gas Town | Planning With Files | Superpowers | Vibe Kanban | Claude-Mem | Showcase |
|---------|------------------------|-------|----------|---------------------|-------------|-------------|------------|----------|
| **Planning Files** | ✅ 4 files | ❌ PRD/JSON | ❌ Git-based | ✅ 3 files | ❌ | ❌ | ❌ | ✅ CLAUDE.md |
| **Fresh Agents** | ✅ Per phase | ✅ Per iteration | ✅ | ❌ | ✅ Subagents | ✅ | ❌ | ❌ |
| **Model Selection** | ✅ Auto | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Multi-Agent** | ❌ Sequential | ❌ | ✅ 20-30 | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Visual UI** | ❌ | ❌ | ✅ Dashboard | ❌ | ❌ | ✅ Kanban | ✅ Web | ❌ |
| **Memory/Search** | ❌ File-based | ❌ Git | ✅ Mailboxes | ❌ | ❌ | ❌ | ✅ Vector | ❌ |
| **Quality Gates** | ❌ | ✅ Tests | ❌ | ❌ | ✅ TDD | ❌ | ❌ | ✅ CI |
| **Git Integration** | ⚠️ Hooks only | ✅ Commits | ✅ Worktrees | ❌ | ✅ Worktrees | ❌ | ❌ | ✅ Actions |
| **Clarifying Qs** | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Summary Gen** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Complexity** | Low | Medium | High | Low | Medium-High | Medium | Medium | Medium |

---

## Gap Analysis: What Others Have That We Don't

### High Value - Consider Adding

| Feature | Source | Effort | Value | Notes |
|---------|--------|--------|-------|-------|
| **Quality Gates** | Ralph, Superpowers | Low | High | Run tests/typecheck before marking phase complete |
| **Git Auto-Commit** | Ralph | Low | Medium | Auto-commit after each phase with descriptive message |
| **Test-First Mode** | Superpowers | Medium | High | Optional TDD enforcement per phase |
| **Progressive Memory Search** | Claude-Mem | High | Medium | Vector search over findings.md history |

### Medium Value - Nice to Have

| Feature | Source | Effort | Value | Notes |
|---------|--------|--------|-------|-------|
| **Git Worktrees** | Gas Town, Superpowers | Medium | Medium | Isolated branches per phase |
| **Intelligent Skill Suggestions** | Showcase | Medium | Medium | Auto-suggest skills based on prompt |
| **GitHub Actions Integration** | Showcase | Low | Medium | Scheduled reviews, dependency audits |
| **Design Refinement Phase** | Superpowers | Low | Medium | Brainstorm alternatives before planning |

### Low Value - Out of Scope

| Feature | Source | Why Skip |
|---------|--------|----------|
| Multi-Agent (20-30) | Gas Town | Complexity explosion, different use case |
| Visual Kanban UI | Vibe Kanban | We're CLI-focused, adds significant complexity |
| Vector Database | Claude-Mem | Overkill for file-based approach |
| Agent Mailboxes | Gas Town | Only needed for parallel agents |

---

## Lessons Learned

### 1. **Keep It File-Based** (Validated)
Planning With Files and our approach work because files are simple, debuggable, and git-friendly. Gas Town's complexity is justified only at scale (20+ agents).

### 2. **Quality Gates Are Essential** (Gap)
Both Ralph and Superpowers enforce tests/typechecks. We should add optional quality gates:
```yaml
execution:
  quality_gates:
    run_tests: true
    typecheck: true
    lint: false
```

### 3. **Git Integration Matters** (Gap)
Ralph's auto-commit per iteration is powerful for:
- Recovery (git log shows exactly what happened)
- Rollback (revert bad phases)
- Audit trail

### 4. **Design Before Plan** (Consider)
Superpowers' design refinement phase prevents "ready-fire-aim":
- Brainstorm 2-3 approaches
- User picks one
- THEN generate detailed plan

### 5. **TDD as Optional Mode** (Consider)
Superpowers enforces RED-GREEN-REFACTOR. This could be a project.yaml option:
```yaml
execution:
  test_first: true  # Write tests before implementation
```

### 6. **Don't Over-Engineer Memory**
Claude-Mem's vector search is impressive but complex. Our file-based findings.md with 2-Action Rule is sufficient for most projects.

### 7. **Hooks Are Underutilized**
Showcase's intelligent skill suggestions via hooks is clever. We could:
- Auto-detect project type (React, Python, etc.)
- Suggest relevant planning approaches
- Warn about anti-patterns

---

## Recommendations

### Priority 1: Quick Wins (Low Effort, High Value)
1. **Add Quality Gates Hook**
   - Optional test/typecheck before phase completion
   - Configurable in project.yaml

2. **Git Auto-Commit Option**
   - Commit after each phase completion
   - Message: "Phase N: [Phase Name] - Complete"

### Priority 2: Medium-Term (Medium Effort, High Value)
3. **Design Refinement Phase**
   - Optional brainstorming before plan generation
   - Present 2-3 approaches, user picks

4. **Test-First Mode**
   - For phases marked as "implementation"
   - Generate test file first, then implementation

### Priority 3: Future Consideration
5. **Intelligent Project Detection**
   - Detect React/Python/Go/etc.
   - Pre-populate relevant references.md entries
   - Suggest appropriate model defaults

6. **Git Worktrees for Phases**
   - Each phase in isolated branch
   - Merge on completion
   - Easy rollback

---

## Positioning Statement

**Simple Claude Conductor** is for developers who want:
- ✅ Structured planning without complexity
- ✅ Smart model selection without configuration
- ✅ Session persistence without databases
- ✅ Fresh context without manual agent spawning
- ❌ NOT multi-agent orchestration at scale
- ❌ NOT visual project management UIs
- ❌ NOT enterprise workflow automation

**Tagline**: "Intelligent project execution with Claude - simple, reliable, file-based."
