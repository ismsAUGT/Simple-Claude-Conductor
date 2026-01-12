# Task Plan: Simple Claude Conductor v4

**Project**: Simple Claude Conductor Simplification improvements.
**Created**: 2026-01-11
**Status**: Planning Complete

---

## Goal

Implement Simple Claude Conductor v4 by adding three workflow skills (prompt-understanding, task-decomposition, output-validation) and enforcement hooks to ensure quality outputs through required understanding verification, success criteria definition, and semantic validation.

**Scope**: Phase 1 - Core Skills + Light Enforcement (reminder mode)

**Out of Scope**: Phase 2 (strong enforcement), Phase 3 (optimization/context management)

---

## Phases

> Each phase must have success criteria. Do not skip this.

---

### Phase 1: Create Workflow Skills

**Status**: Complete

**Description**:
Create three new skills in `.claude/skills/` with complete SKILL.md files. Each skill provides instructions for a critical workflow step: understanding before planning, decomposition with success criteria, and validation before completion.

**Success Criteria**:
- [ ] Directory `.claude/skills/prompt-understanding/` exists with SKILL.md file
- [ ] Directory `.claude/skills/task-decomposition/` exists with SKILL.md file
- [ ] Directory `.claude/skills/output-validation/` exists with SKILL.md file
- [ ] Each SKILL.md contains the complete content from PRD artifacts A, B, and C (verified by checking key sections exist: Purpose, When to Run, Process, Outputs)
- [ ] All three SKILL.md files are valid markdown (no syntax errors)

**Outputs**:
- `.claude/skills/prompt-understanding/SKILL.md`: Instructions for understanding verification before planning
- `.claude/skills/task-decomposition/SKILL.md`: Instructions for creating phases with success criteria
- `.claude/skills/output-validation/SKILL.md`: Instructions for semantic validation before completion

**Dependencies**: None

---

### Phase 2: Create Enforcement Hooks

**Status**: Complete

**Description**:
Create two hook scripts that enforce the workflow: pre-planning-check.sh ensures Domain Understanding exists before planning, and phase-completion-check.sh ensures validation was performed before marking phases complete. Both hooks operate in reminder mode (warn but allow).

**Success Criteria**:
- [ ] File `.claude/hooks/pre-planning-check.sh` exists with executable permissions
- [ ] File `.claude/hooks/phase-completion-check.sh` exists with executable permissions
- [ ] pre-planning-check.sh contains logic to check for Domain Understanding section in findings.md
- [ ] phase-completion-check.sh contains logic to check for validation entries in progress.md
- [ ] Both scripts use exit 0 (reminder mode, not blocking)
- [ ] Scripts are valid bash syntax (no syntax errors)

**Outputs**:
- `.claude/hooks/pre-planning-check.sh`: Hook to remind about prompt-understanding skill
- `.claude/hooks/phase-completion-check.sh`: Hook to remind about output-validation skill

**Dependencies**: None (independent of Phase 1)

---

### Phase 3: Update Configuration Files

**Status**: Complete

**Description**:
Update CLAUDE.md with the workflow skills documentation section and update settings.local.json to register the hooks. This makes the skills discoverable and activates the enforcement hooks.

**Success Criteria**:
- [ ] CLAUDE.md contains new "Critical Workflow Skills" section (verified by searching for "## Critical Workflow Skills")
- [ ] CLAUDE.md section documents all three skills with examples of good vs bad usage
- [ ] settings.local.json contains hooks configuration for PreToolUse and PostToolUse
- [ ] settings.local.json hooks reference the correct script paths (.claude/hooks/*.sh)
- [ ] Both updated files are valid (markdown for CLAUDE.md, JSON for settings.local.json)

**Outputs**:
- Updated `CLAUDE.md`: Documents the three workflow skills and their enforcement
- Updated `.claude/settings.local.json`: Registers hooks to trigger on Edit/Write operations

**Dependencies**: Phase 2 must be complete (hooks must exist before configuring them)

---

### Phase 4: Update Planning Templates

**Status**: Complete

**Description**:
Verify that findings.md template has adequate Domain Understanding section, and ensure task-plan.md template includes the phase structure with success criteria placeholders.

**Success Criteria**:
- [ ] Template `.claude/skills/planning-with-files/templates/findings.md` contains "## Domain Understanding" section
- [ ] Domain Understanding section has subsections for: Job to be Done, Domain Familiarity, Key Terminology, Research Conducted, Assumptions, Remaining Uncertainties
- [ ] Created or updated task-plan.md template includes phase structure with success criteria fields
- [ ] Template demonstrates proper success criteria format (specific, verifiable)

**Outputs**:
- Verified/updated `.claude/skills/planning-with-files/templates/findings.md`
- Created/updated `.claude/skills/planning-with-files/templates/task-plan.md`

**Dependencies**: None

---

### Phase 5: Validation and Documentation

**Status**: Complete

**Description**:
Verify all files are in place, properly formatted, and the implementation matches the PRD. Update STATUS.md with completion summary and next steps for the user.

**Success Criteria**:
- [ ] All 8 implementation checklist items from PRD Phase 1 are complete
- [ ] File structure matches expected layout (skills in .claude/skills/, hooks in .claude/hooks/)
- [ ] No placeholder text remains (all [brackets] filled in or removed where appropriate)
- [ ] STATUS.md updated with completion status and clear next steps
- [ ] STATUS.md indicates how to test the workflow (run a sample task)

**Outputs**:
- Updated `STATUS.md`: Executive summary of what was implemented
- Updated `docs/planning/progress.md`: Session log of implementation
- `output/cost_report.md`: Cost breakdown for this session (generated at end)

**Dependencies**: Phases 1-4 must be complete

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Hook scripts may not work on Windows | Use Git Bash compatible syntax, provide .bat alternatives if needed |
| settings.local.json hook syntax may be outdated | Test hook trigger, adjust format if needed |
| Skills may be too verbose for daily use | This is Phase 1, can refine in Phase 2 based on usage |

---

## Success Metrics

**Primary metric**: All Phase 1 checklist items from PRD completed

**Quality indicators**:
- Skills are clear and actionable
- Hooks provide helpful reminders without blocking workflow
- Configuration is correct and hooks trigger appropriately

**Efficiency**:
- Implementation should complete in one session
- Estimated cost: <$5 (primarily file creation and configuration)
