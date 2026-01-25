# Task Plan: Simple Claude Conductor UI Overhaul

## Goal

Build a local web UI that guides non-technical users through the Simple Claude Conductor workflow without requiring terminal commands, markdown editing, or file switching.

**Current Focus**: PROJECT COMPLETE

---

## Phase 1: Infrastructure & Portable Python Bundle

**Priority**: HIGHEST - Foundation for everything else
**Complexity**: Medium
**Model**: Sonnet
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] All tasks complete

### Validation Summary
- **Confidence**: 85%
- **See**: [progress.md](progress.md) for details

---

## Phase 2: Archive/Reset Flow & Guardrails

**Priority**: HIGH - Enables clean project lifecycle
**Complexity**: Medium
**Model**: Sonnet
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] 2.1 Implement archive API endpoint (/api/archive) - existed from Phase 1
- [x] 2.2 Create archive folder structure with timestamps
- [x] 2.3 Update CLAUDE.md to exclude archive from searches
- [x] 2.4 Implement reset flow (/api/reset - archive + clear working files)
- [x] 2.5 Add archive notification to UI (Project Management card)
- [x] 2.6 Update .gitignore for archive folder

### Success Criteria
- [x] Archive button creates timestamped backup
- [x] Claude ignores archive/ in all searches
- [x] Reset clears working files while preserving archives

### Validation Summary
- **Confidence**: 90%
- **See**: [progress.md](progress.md) for details

---

## Phase 3: Configuration Form

**Priority**: MEDIUM - Core user experience
**Complexity**: Medium
**Model**: Sonnet
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] 3.1 Design HTML form layout
- [x] 3.2 Implement config read/write API (existed from Phase 1)
- [x] 3.3 Add Claude authentication check (existed from Phase 1)
- [x] 3.4 List reference files endpoint (existed from Phase 1)
- [x] 3.5 Form validation
- [x] 3.6 "Review Prompt Quality" button

### Success Criteria
- [x] Users can configure project without editing markdown
- [x] Auth status shows correctly
- [x] Reference files are visible
- [x] Prompt quality review works

### Validation Summary
- **Confidence**: 90%
- **See**: [progress.md](progress.md) for details

---

## Phase 4: Status Polling & Progress Display

**Priority**: MEDIUM - User visibility
**Complexity**: Medium
**Model**: Sonnet
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] 4.1 Implement status API endpoint (existed from Phase 1)
- [x] 4.2 Parse STATUS.md for phase info (existed from Phase 1)
- [x] 4.3 Add polling every 3 seconds (existed from Phase 1)
- [x] 4.4 Progress bar visualization (existed from Phase 1)
- [x] 4.5 Stall detection (>60s = possible permission prompt)

### Success Criteria
- [x] Live progress display works
- [x] Phase completion is detected
- [x] Stall warning appears when needed

### Validation Summary
- **Confidence**: 95%
- **See**: [progress.md](progress.md) for details

---

## Phase 5: Question Integration

**Priority**: LOWER - Enhancement
**Complexity**: Low
**Model**: Sonnet
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] 5.1 Implement questions API
- [x] 5.2 Parse Questions_For_You.md
- [x] 5.3 Render inline form
- [x] 5.4 Write answers back
- [x] 5.5 "Skip - Let Claude Decide" button

### Success Criteria
- [x] Questions appear in UI automatically
- [x] Answers are written back correctly
- [x] Skip functionality works

### Validation Summary
- **Confidence**: 90%
- **See**: [progress.md](progress.md) for details

---

## Phase 6: Polish & Edge Cases

**Priority**: LOWEST - Nice to have
**Complexity**: Low
**Model**: Haiku
**Status**: COMPLETE (2026-01-25)

### Tasks
- [x] 6.1 Error handling for all APIs
- [x] 6.2 Graceful shutdown handling
- [x] 6.3 Better styling/animations
- [x] 6.4 Cost report display
- [x] 6.5 Session persistence (via polling - state reloaded on page refresh)

### Success Criteria
- [x] No unhandled errors
- [x] UI looks polished
- [x] Cost metrics visible

### Validation Summary
- **Confidence**: 90%
- **See**: [progress.md](progress.md) for details

---

## Decisions Log

| Decision | Resolution | Date |
|----------|------------|------|
| Portable Python source | Official embeddable package from python.org | 2026-01-25 |
| Python version | 3.12.x (stable) | 2026-01-25 |
| Architecture | 64-bit only | 2026-01-25 |
| Permissions approach | Comprehensive allow list (no bypass) | Previous session |
| Archive browsing | No browsing - just notify location | Previous session |

---

## References

- [UI_OVERHAUL_PLAN.md](UI_OVERHAUL_PLAN.md) - Detailed specifications
- [COMPREHENSIVE_PERMISSIONS.md](COMPREHENSIVE_PERMISSIONS.md) - Permissions strategy
- [findings.md](findings.md) - Research and domain understanding
