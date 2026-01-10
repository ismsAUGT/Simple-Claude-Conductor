# Claude Project Executor - Product Requirements Document

**Version**: 1.0
**Date**: 2026-01-10
**Status**: Draft

---

## Executive Summary

Claude Project Executor is a reusable project template that transforms Claude from a general-purpose assistant into an intelligent project execution engine. Users provide a prompt describing their goal, and the system:

1. Generates a complete implementation plan
2. Asks clarifying questions to refine scope
3. Executes the plan autonomously with intelligent agent spawning
4. Manages context efficiently through fresh agents per phase
5. Switches models (Haiku/Sonnet/Opus) based on task complexity
6. Produces executive summaries and lessons learned

The template is designed to be cloned into any new project, configured via YAML, and immediately operational.

---

## Problem Statement

### Current Pain Points

1. **Context Degradation**: Long Claude conversations lose quality as context fills
2. **Manual Orchestration**: Users must manually manage multi-step projects
3. **No Persistent Memory**: Each session starts fresh without project context
4. **Inconsistent Quality**: Complex tasks need Opus; simple tasks waste tokens on it
5. **No Structured Workflow**: Ad-hoc implementation leads to missed requirements
6. **Documentation Drift**: Plans and progress diverge from reality

### Target User

Developers who want to:
- Execute complex multi-step projects with Claude
- Maintain context across sessions
- Minimize token usage through smart model selection
- Get consistent, high-quality results without micromanagement

---

## Solution Overview

### Core Concept: Planning-with-Files + Intelligent Execution

The system separates concerns into:
1. **Planning Layer**: Four persistent files that survive across sessions
2. **Execution Layer**: Fresh agents spawned per phase with injected context
3. **Model Layer**: Automatic model selection based on task complexity
4. **Configuration Layer**: YAML settings for customization

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        User Prompt                                   │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Plan Generator                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │ Parse Prompt    │→ │ Generate Plan   │→ │ Clarifying Questions│  │
│  │ (Haiku)         │  │ (Opus)          │  │ (Sonnet)            │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Planning Files (Persistent)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │
│  │ task-plan.md │ │ findings.md  │ │ progress.md  │ │references.md│ │
│  │ (Goal/Phases)│ │ (Discoveries)│ │ (Session Log)│ │ (Files)     │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Phase Executor                                  │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ For each phase:                                              │    │
│  │   1. Read task-plan.md → Extract phase requirements          │    │
│  │   2. Determine complexity → Select model                     │    │
│  │   3. Spawn fresh Task agent with context injection           │    │
│  │   4. Agent executes → Updates findings.md, progress.md       │    │
│  │   5. Agent completes → Move to next phase                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Summary Generator                               │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ 1. Aggregate all progress.md entries                         │    │
│  │ 2. Generate executive summary (Sonnet)                       │    │
│  │ 3. Extract lessons learned                                   │    │
│  │ 4. Produce feedback report                                   │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Functional Requirements

### FR1: Project Initialization

**FR1.1**: Template provides a `project-init.sh` script that:
- Creates `.claude/` folder structure
- Copies skills, hooks, and settings
- Generates `project.yaml` configuration file
- Creates `docs/planning/` folder with empty planning files

**FR1.2**: Initialization prompts for:
- Project name
- Default model preference
- Bypass permissions (yes/no)
- Interrupt for questions (yes/no)

### FR2: Plan Generation

**FR2.1**: System parses user prompt and generates:
- Goal statement (1-2 sentences)
- Success criteria (3-5 bullet points)
- Phase breakdown (numbered phases with deliverables)
- Risk assessment (potential blockers)

**FR2.2**: Plan generation uses Opus model for quality

**FR2.3**: Generated plan saved to `task-plan.md` with structure:
```markdown
## Goal
[Goal statement]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Phases
### Phase 1: [Name]
- **Deliverables**: [List]
- **Complexity**: [Low/Medium/High]
- **Model**: [Haiku/Sonnet/Opus]

### Phase 2: [Name]
...

## Risks
| Risk | Mitigation |
|------|------------|
| ... | ... |

## Decisions
| # | Decision | Rationale | Date |
|---|----------|-----------|------|
```

### FR3: Clarifying Questions

**FR3.1**: After plan generation, system identifies ambiguities and generates clarifying questions

**FR3.2**: Questions presented in priority order (blocking questions first)

**FR3.3**: User can:
- Answer questions → Refine plan
- Skip questions → Proceed with assumptions
- Request more questions → Deeper analysis

**FR3.4**: Behavior controlled by `interrupt_for_questions` config:
- `true`: Always stop for questions
- `false`: Proceed with best-guess assumptions, log assumptions in task-plan.md

### FR4: Phase Execution

**FR4.1**: Executor reads `task-plan.md` and processes phases sequentially

**FR4.2**: For each phase:
1. Extract phase requirements from task-plan.md
2. Read relevant sections of findings.md and references.md
3. Determine complexity and select model
4. Spawn fresh Task agent with context injection
5. Monitor agent completion
6. Validate deliverables against success criteria
7. Update progress.md with phase results

**FR4.3**: Agent receives injected context:
```
## Context Injection
You are executing Phase [N]: [Name]

### Goal
[From task-plan.md]

### Phase Requirements
[From task-plan.md Phase N section]

### Relevant Findings
[From findings.md - phase-relevant entries]

### Key Files
[From references.md]

### Previous Progress
[From progress.md - last 2 phase summaries]
```

**FR4.4**: Context window management:
- Fresh agent per phase (no context accumulation)
- Only inject relevant context (not entire history)
- Agent updates findings.md every 2 research operations (2-Action Rule)

### FR5: Model Selection

**FR5.1**: System determines model based on phase complexity:

| Complexity | Model | When to Use |
|------------|-------|-------------|
| Low | Haiku | Simple file operations, formatting, documentation |
| Medium | Sonnet | Standard implementation, bug fixes, refactoring |
| High | Opus | Architecture decisions, complex algorithms, debugging |

**FR5.2**: Complexity determined by:
- Phase description keywords (architecture → High, format → Low)
- Number of files involved (1-2 files → Low, 10+ → High)
- Explicit `complexity` field in task-plan.md

**FR5.3**: Model can be overridden:
- Per-phase in task-plan.md: `- **Model**: Opus`
- Globally in project.yaml: `default_model: sonnet`

### FR6: Hooks System

**FR6.1**: UserPromptSubmit hooks for:
- File discovery reminder (MCP-First workflow)
- Planning file check (ensure files exist before execution)

**FR6.2**: PreToolUse hooks for:
- Branch protection (prevent force push to main)
- File organization guard (warn on ad-hoc file creation)
- Bypass control (based on `bypass_permissions` config)

**FR6.3**: PostToolUse hooks for:
- Findings update reminder (2-Action Rule enforcement)
- Progress logging

### FR7: Summary Generation

**FR7.1**: After all phases complete, system generates:

**Executive Summary**:
- Project goal (restated)
- What was accomplished (per phase)
- Key decisions made
- Files created/modified
- Time to completion (session count)

**Lessons Learned**:
- What worked well
- What could be improved
- Assumptions that proved wrong
- Recommendations for similar projects

**FR7.2**: Summary saved to `docs/planning/execution-summary.md`

**FR7.3**: Feedback incorporated into `findings.md` for future reference

---

## Configuration

### project.yaml Schema

```yaml
# Claude Project Executor Configuration
version: "1.0"

project:
  name: "My Project"
  description: "Brief project description"

execution:
  # Default model for unspecified phases
  default_model: "sonnet"  # haiku | sonnet | opus

  # Skip confirmation prompts during execution
  bypass_permissions: false

  # Stop for clarifying questions or proceed with assumptions
  interrupt_for_questions: true

  # Maximum phases before requiring user confirmation
  max_auto_phases: 5

  # Generate summary after execution
  generate_summary: true

models:
  # Model mapping for complexity levels
  low: "haiku"
  medium: "sonnet"
  high: "opus"

paths:
  # Where planning files live
  planning_dir: "docs/planning"

  # Where reports go
  reports_dir: "docs/planning/reports"

  # Where completed work is archived
  archive_dir: "docs/planning/archive"

hooks:
  # Enable/disable specific hooks
  mcp_reminder: true
  branch_protection: true
  file_guard: true
  findings_reminder: true
```

---

## Project Structure

```
project-root/
├── .claude/
│   ├── README.md                    # Overview and quick reference
│   ├── instructions.md              # Core workflow principles
│   ├── workflow-guide.md            # Agent usage patterns
│   ├── settings.local.json          # Hook configurations
│   │
│   ├── hooks/
│   │   ├── mcp-reminder.sh          # File discovery reminder
│   │   ├── branch-protection.sh     # Git safety
│   │   ├── file-guard.sh            # Organization enforcement
│   │   └── findings-reminder.sh     # 2-Action Rule
│   │
│   └── skills/
│       ├── planning-with-files/
│       │   ├── SKILL.md             # Four-file planning pattern
│       │   ├── scripts/
│       │   │   └── init-planning.sh # Initialize planning files
│       │   └── templates/
│       │       ├── task-plan.md
│       │       ├── findings.md
│       │       ├── progress.md
│       │       └── references.md
│       │
│       └── project-executor/
│           ├── SKILL.md             # Execution orchestration
│           └── scripts/
│               ├── execute-plan.sh  # Main execution script
│               └── generate-summary.sh
│
├── docs/
│   └── planning/
│       ├── README.md
│       ├── task-plan.md
│       ├── findings.md
│       ├── progress.md
│       ├── references.md
│       ├── reports/
│       └── archive/
│
├── project.yaml                     # Project configuration
├── CLAUDE.md                        # Project instructions for Claude
└── project-init.sh                  # First-run initialization
```

---

## Key Workflows

### Workflow 1: New Project Setup

```bash
# 1. Clone the template
git clone https://github.com/your-org/claude-project-executor.git my-project
cd my-project

# 2. Initialize the project
./project-init.sh
# Prompts for: project name, default model, settings

# 3. Edit project.yaml if needed
# 4. Start Claude Code and provide your prompt
```

### Workflow 2: Plan Generation and Execution

```
User: I want to build a REST API for user management with JWT auth

Claude:
1. [Opus] Generates plan with 5 phases:
   - Phase 1: Database schema design
   - Phase 2: User model and repository
   - Phase 3: Authentication endpoints
   - Phase 4: User CRUD endpoints
   - Phase 5: Testing and documentation

2. [Sonnet] Asks clarifying questions:
   - What database? (PostgreSQL/MySQL/SQLite)
   - Framework preference? (Express/Fastify/Hono)
   - Need email verification? (Yes/No)

3. User answers questions

4. [Execution] Spawns agents per phase:
   - Phase 1 agent (Haiku): Creates schema.sql
   - Phase 2 agent (Sonnet): Implements User model
   - Phase 3 agent (Opus): Implements JWT auth
   - Phase 4 agent (Sonnet): Implements CRUD
   - Phase 5 agent (Sonnet): Writes tests

5. [Sonnet] Generates executive summary
```

### Workflow 3: Mid-Execution Recovery

If a session is interrupted:

```
1. Claude reads task-plan.md → Identifies current phase
2. Claude reads progress.md → Finds last completed work
3. Claude continues from interruption point
4. No context loss due to persistent files
```

---

## Core Principles (Embedded in Template)

These principles are baked into `.claude/instructions.md`:

### 1. Stub → Review → Implement
Never write complete code in one pass. Structure first, then fill in.

### 2. MCP-First for File Discovery
Always try MCP tools before Grep/Glob. Add found files to references.md.

### 3. 2-Action Rule
Update findings.md every 2 research operations. Prevents knowledge loss.

### 4. 3-Strike Protocol
Try 3 approaches before escalating. Document failures in task-plan.md Errors table.

### 5. Fresh Agents, Persistent Files
Spawn new agents per phase. Let files carry context, not agent memory.

### 6. Minimal Implementation
Only implement what's requested. No speculative features.

### 7. Continuous Documentation
Update planning files as work progresses. Future sessions depend on this.

---

## Model Selection Logic

### Complexity Scoring Algorithm

```python
def determine_complexity(phase):
    score = 0

    # Keyword analysis
    high_keywords = ['architecture', 'design', 'complex', 'algorithm', 'security']
    medium_keywords = ['implement', 'build', 'create', 'refactor', 'test']
    low_keywords = ['format', 'rename', 'move', 'document', 'simple']

    description = phase.description.lower()

    for kw in high_keywords:
        if kw in description:
            score += 3
    for kw in medium_keywords:
        if kw in description:
            score += 2
    for kw in low_keywords:
        if kw in description:
            score += 1

    # File count factor
    file_count = len(phase.files_involved)
    if file_count > 10:
        score += 3
    elif file_count > 5:
        score += 2
    elif file_count > 2:
        score += 1

    # Explicit override
    if phase.explicit_model:
        return phase.explicit_model

    # Return based on score
    if score >= 6:
        return "opus"
    elif score >= 3:
        return "sonnet"
    else:
        return "haiku"
```

---

## Hook Implementations

### mcp-reminder.sh (UserPromptSubmit)

```bash
#!/bin/bash
# Remind about MCP-First when searching

PROMPT_LOWER=$(echo "$CLAUDE_PROMPT" | tr '[:upper:]' '[:lower:]')
SEARCH_KEYWORDS="find|search|where|locate|look for|grep|glob"

if echo "$PROMPT_LOWER" | grep -qE "$SEARCH_KEYWORDS"; then
    MESSAGE="💡 **MCP-First**: Before Grep/Glob, try MCP tools for file discovery. Add results to references.md."
    echo "{\"result\": \"continue\", \"message\": \"$MESSAGE\"}"
else
    echo "{\"result\": \"continue\"}"
fi
```

### branch-protection.sh (PreToolUse)

```bash
#!/bin/bash
# Prevent dangerous git operations

COMMAND="$CLAUDE_TOOL_INPUT"

# Block force push to main/master
if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force.*\s+(main|master)"; then
    echo "{\"result\": \"block\", \"message\": \"⚠️ Force push to main/master blocked.\"}"
    exit 0
fi

# Warn on any force push
if echo "$COMMAND" | grep -qE "git\s+push\s+.*--force"; then
    echo "{\"result\": \"continue\", \"message\": \"⚠️ Force push detected. Confirm this is intentional.\"}"
    exit 0
fi

echo "{\"result\": \"continue\"}"
```

### file-guard.sh (PreToolUse)

```bash
#!/bin/bash
# Prevent ad-hoc file creation in planning directory

FILE_PATH="$CLAUDE_TOOL_INPUT"
PLANNING_DIR="docs/planning"

if echo "$FILE_PATH" | grep -q "$PLANNING_DIR/[^/]*\.md$"; then
    FILENAME=$(basename "$FILE_PATH")
    ALLOWED="README.md|task-plan.md|findings.md|progress.md|references.md"

    if ! echo "$FILENAME" | grep -qE "^($ALLOWED)$"; then
        MESSAGE="⚠️ Creating file in planning root. Consider: reports/ for large reports, archive/ for completed work."
        echo "{\"result\": \"continue\", \"message\": \"$MESSAGE\"}"
        exit 0
    fi
fi

echo "{\"result\": \"continue\"}"
```

### findings-reminder.sh (PostToolUse)

```bash
#!/bin/bash
# Remind to update findings.md after research operations

TOOL_NAME="$CLAUDE_TOOL_NAME"
RESEARCH_TOOLS="Grep|Glob|Read|WebSearch|WebFetch"

# Track operation count (simplified - real implementation would persist)
if echo "$TOOL_NAME" | grep -qE "$RESEARCH_TOOLS"; then
    echo "{\"result\": \"continue\", \"message\": \"📝 Research operation detected. Remember: Update findings.md every 2 research operations (2-Action Rule).\"}"
else
    echo "{\"result\": \"continue\"}"
fi
```

---

## SKILL.md Templates

### planning-with-files/SKILL.md (Key Sections)

```markdown
---
name: planning-with-files
description: Four-file pattern for complex multi-session projects. Use when: 5+ tasks, multi-session, high uncertainty, or cross-system changes.
---

# Planning With Files

## When to Use
- 5+ implementation tasks
- Work spans multiple sessions
- High uncertainty requiring research
- Changes across multiple systems

## The Four Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| task-plan.md | Goal, phases, decisions | Per major decision |
| findings.md | Discoveries, research results | Every 2 research ops |
| progress.md | Session logs, what was done | End of each session |
| references.md | Files found via MCP | When files discovered |

## Key Rules

1. **Re-read task-plan.md before major decisions**
2. **2-Action Rule**: Update findings.md every 2 research operations
3. **3-Strike Protocol**: Try 3 approaches before escalating
4. **MCP-First**: Use MCP before Grep/Glob, add to references.md
```

### project-executor/SKILL.md (Key Sections)

```markdown
---
name: project-executor
description: Orchestrates plan execution with fresh agents per phase and automatic model selection.
---

# Project Executor

## Prerequisites
1. planning-with-files initialized
2. task-plan.md populated with phases
3. project.yaml configured

## Execution Flow

1. Read task-plan.md → Parse phases
2. For each phase:
   a. Determine complexity → Select model
   b. Prepare context injection
   c. Spawn Task agent
   d. Monitor completion
   e. Validate deliverables
   f. Update progress.md
3. Generate summary

## Context Injection Template

When spawning an agent, inject:
- Goal (from task-plan.md)
- Phase requirements
- Relevant findings (filtered)
- Key files (from references.md)
- Last 2 progress entries
```

---

## Success Metrics

### Quality Metrics
- **Plan Accuracy**: % of phases that complete without re-planning
- **Context Efficiency**: Average context usage per phase (target: <50%)
- **Model Optimization**: Cost savings from Haiku/Sonnet usage vs all-Opus

### User Experience Metrics
- **Time to First Plan**: < 2 minutes from prompt
- **Clarifying Question Quality**: User answers resolve ambiguity 80%+ of time
- **Recovery Success**: 100% of interrupted sessions resume correctly

### Technical Metrics
- **Agent Spawn Success**: 99%+ of agents complete their phase
- **File Integrity**: Zero conflicts between agent updates
- **Hook Reliability**: 100% hook execution on matching events

---

## Implementation Phases

### Phase 1: Core Template (MVP)
- `.claude/` folder structure
- planning-with-files skill with templates
- Basic project-executor (manual model selection)
- Essential hooks (branch-protection, file-guard)
- project.yaml configuration

### Phase 2: Intelligent Execution
- Automatic complexity scoring
- Model selection algorithm
- Context injection optimization
- 2-Action Rule enforcement hook

### Phase 3: Plan Generation
- Prompt parsing with Opus
- Phase breakdown generation
- Clarifying question generation
- Plan refinement workflow

### Phase 4: Summary & Feedback
- Executive summary generation
- Lessons learned extraction
- Feedback report format
- Archive workflow

### Phase 5: Polish & Documentation
- User documentation
- Example projects
- Troubleshooting guide
- Video walkthrough

---

## Reference Implementation

This PRD is based on a working implementation in the Squad Survivors project:
- Repository: `SquadSurvivorsAndrew`
- Location: `.claude/skills/planning-with-files/`

Key files to reference:
- `.claude/instructions.md` - Core principles
- `.claude/workflow-guide.md` - Agent patterns
- `.claude/skills/planning-with-files/SKILL.md` - Full skill (900 lines)
- `.claude/hooks/*.sh` - Hook implementations
- `docs/currentSystem/` - Example planning folder

---

## Appendix A: Planning File Templates

### task-plan.md Template

```markdown
# Task: [Task Name]

**Created**: [Date]
**Status**: In Progress | Complete

## Goal
[1-2 sentence goal statement]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Phases

### Phase 1: [Name]
**Status**: Not Started | In Progress | Complete
**Complexity**: Low | Medium | High
**Model**: Haiku | Sonnet | Opus
**Deliverables**:
- [ ] Deliverable 1
- [ ] Deliverable 2

### Phase 2: [Name]
...

## Decisions Log
| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| D1 | [Decision] | [Why] | [Date] |

## Errors & Blockers
| # | Error | Resolution | Status |
|---|-------|------------|--------|
| E1 | [Error] | [Fix] | Resolved/Open |

## Assumptions
- [Assumption 1]
- [Assumption 2]
```

### findings.md Template

```markdown
# Findings: [Task Name]

**Last Updated**: [Date]

## Summary
[Brief summary of key discoveries]

## Discoveries

### [Date] - [Topic]
- **Source**: [File/MCP/Research]
- **Finding**: [What was discovered]
- **Implication**: [How this affects the plan]

### [Date] - [Topic]
...

## Patterns Identified
- [Pattern 1]
- [Pattern 2]

## Questions Answered
| Question | Answer | Source |
|----------|--------|--------|
| [Q1] | [A1] | [Source] |
```

### progress.md Template

```markdown
# Progress: [Task Name]

## Session Log

### Session [N] - [Date]
**Phase**: [Current Phase]
**Model**: [Model Used]
**Duration**: [Time]

**Completed**:
- [x] Task 1
- [x] Task 2

**Blockers Encountered**:
- [Blocker and resolution]

**Next Steps**:
- [ ] Next task 1
- [ ] Next task 2

---

### Session [N-1] - [Date]
...
```

### references.md Template

```markdown
# References: [Task Name]

## Key Files

### Source Code
| File | Purpose | Found Via |
|------|---------|-----------|
| `path/to/file.ext` | [Purpose] | MCP/Grep |

### Documentation
| File | Purpose | Found Via |
|------|---------|-----------|
| `docs/file.md` | [Purpose] | MCP |

### Configuration
| File | Purpose | Found Via |
|------|---------|-----------|
| `config.yaml` | [Purpose] | Grep |

## External Resources
- [Link 1]: [Description]
- [Link 2]: [Description]
```

---

## Appendix B: CLAUDE.md Template

```markdown
# CLAUDE.md

This project uses Claude Project Executor for intelligent plan execution.

## Quick Start

1. Describe what you want to build
2. Claude generates a plan and asks clarifying questions
3. Approve the plan to begin execution
4. Claude executes phases with optimal model selection
5. Receive an executive summary when complete

## Configuration

Edit `project.yaml` to customize:
- Default model (haiku/sonnet/opus)
- Whether to interrupt for questions
- Permission bypass settings

## Key Commands

- "Generate a plan for [description]" - Start planning
- "Execute the plan" - Begin phase execution
- "Show progress" - View current status
- "Summarize" - Generate executive summary

## Documentation

- `.claude/README.md` - System overview
- `.claude/instructions.md` - Core principles
- `docs/planning/` - Active planning files

## Principles

1. **Stub → Review → Implement**: Structure before code
2. **2-Action Rule**: Update findings every 2 research operations
3. **Fresh Agents**: New agent per phase for clean context
4. **Continuous Documentation**: Files are the memory
```

---

## Appendix C: Cost Optimization Examples

### Scenario: 10-Phase Project

**Without model selection (all Opus)**:
- 10 phases × ~50K tokens average = 500K tokens
- Cost: ~$7.50 (at $15/M tokens)

**With intelligent model selection**:
- 3 phases Opus (complex) = 150K tokens × $15/M = $2.25
- 5 phases Sonnet (medium) = 250K tokens × $3/M = $0.75
- 2 phases Haiku (simple) = 100K tokens × $0.25/M = $0.03
- Total: ~$3.03 (60% savings)

### Scenario: Research-Heavy Project

**Without 2-Action Rule**:
- Agent context fills with raw research
- Quality degrades after ~100K tokens
- Requires manual intervention

**With 2-Action Rule**:
- Findings summarized every 2 operations
- Agent receives distilled knowledge
- Quality maintained throughout

---

*End of PRD*
