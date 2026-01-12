# References: Simple Claude Conductor v4

**Project**: Simple Claude Conductor Simplification improvements.
**Last Updated**: 2026-01-11

---

## Project Files

| File | Purpose | Status |
|------|---------|--------|
| START_HERE.md | User's project configuration and goals | Read |
| project.yaml | System configuration | Read |
| CLAUDE.md | Instructions for Claude during execution | To be updated |
| STATUS.md | User-facing progress and next steps | Updated |

---

## Reference Materials

| File | Type | Purpose | Notes |
|------|------|---------|-------|
| File_References_For_Your_Project/Improvements_Prompt.md | PRD | Complete specification with implementation artifacts | Primary source |
| File_References_For_Your_Project/README.md | Info | Guidance on using reference folder | Not needed for this task |

---

## PRD Artifacts Referenced

The PRD contains 8 ready-to-use artifacts:

| Artifact | Purpose | Target File |
|----------|---------|-------------|
| A: prompt-understanding Skill | Workflow skill for understanding verification | `.claude/skills/prompt-understanding/SKILL.md` |
| B: task-decomposition Skill | Workflow skill for planning with success criteria | `.claude/skills/task-decomposition/SKILL.md` |
| C: output-validation Skill | Workflow skill for semantic validation | `.claude/skills/output-validation/SKILL.md` |
| D: Updated findings.md Template | Enhanced template with Domain Understanding | `.claude/skills/planning-with-files/templates/findings.md` |
| E: CLAUDE.md Additions | Documentation of workflow skills | Append to `CLAUDE.md` |
| F: Hook Specifications | Two bash scripts for enforcement | `.claude/hooks/*.sh` |
| G: settings.local.json Configuration | Hook registration | `.claude/settings.local.json` |
| H: Phase Structure Template | task-plan.md phase format | Reference for future plans |

---

## External References

None required - all implementation details are in the PRD.

---

## Code Patterns

**Hook Script Pattern**:
- Check if required file exists
- Check if required section/content exists
- Exit 0 for reminder mode (Phase 1)
- Exit 1 for block mode (Phase 2)

**Skill SKILL.md Pattern**:
- Front matter with name and description
- Purpose section
- When to Run section
- Process section (step-by-step)
- Outputs section
- Quality Checklist
- Examples (good vs bad)
- Common Mistakes to Avoid
