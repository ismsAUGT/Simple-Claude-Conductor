# Simple Claude Conductor - Architecture

## Current System Overview

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    User Browser                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  conductor.html (1760 lines - too big!)        │   │
│  │  - Inline CSS (~700 lines)                      │   │
│  │  - Inline JS  (~1000 lines)                     │   │
│  │  - HTML structure                               │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
                    HTTP Requests (AJAX)
                            │
┌─────────────────────────────────────────────────────────┐
│              Flask Server (app.py)                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │  API Endpoints (24 routes)                      │   │
│  │  - Status, Config, Claude Control               │   │
│  │  - File Management, Questions                   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  State Management (file-based)                  │   │
│  │  - STATUS.md (current state)                    │   │
│  │  - config/project-config.json                   │   │
│  │  - docs/planning/*.md                           │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Process Management                             │   │
│  │  - Spawns Claude Code subprocess                │   │
│  │  - Global `claude_process` variable             │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
                    subprocess.Popen
                            │
┌─────────────────────────────────────────────────────────┐
│            Claude Code CLI Process                       │
│  - Runs in background                                   │
│  - Reads/writes markdown files                          │
│  - Updates STATUS.md                                    │
└─────────────────────────────────────────────────────────┘
```

---

## Current Problems

### 1. **Monolithic Frontend**
- **Problem**: 1760 lines in one HTML file
- **Impact**:
  - CSS conflicts (DaisyUI vs custom styles)
  - Hard to debug
  - Can't cache CSS/JS separately
  - Difficult to maintain

### 2. **Unclear State Machine**
- **Problem**: State is scattered across:
  - STATUS.md (text parsing)
  - config/project-config.json
  - Subprocess existence
  - Multiple markdown files
- **Impact**:
  - Race conditions
  - Inconsistent state
  - Hard to reason about flow

### 3. **No Separation of Concerns**
- **Problem**: Frontend mixes:
  - Presentation (CSS)
  - Behavior (JS)
  - Structure (HTML)
  - State polling logic
  - API calls
- **Impact**: Everything breaks together

### 4. **File-Based State**
- **Problem**: Using markdown files as database
- **Impact**:
  - Concurrent access issues
  - Text parsing fragility
  - No transactional updates
  - Race conditions with Claude subprocess

### 5. **Global Process Variable**
- **Problem**: `claude_process` is global in Flask
- **Impact**:
  - Lost on server restart
  - No persistence
  - Can't track multiple sessions

---

## Proposed Clean Architecture

### Core Principles

1. **Separation of Concerns**: Frontend, API, State, Process Management
2. **Single Source of Truth**: One state store
3. **Clear State Machine**: Explicit states and transitions
4. **Loose Coupling**: Components interact via clean interfaces
5. **Stateless API**: Server doesn't hold state in memory

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                         FRONTEND                              │
│  ┌────────────┬────────────┬────────────┬────────────┐      │
│  │ HTML       │ CSS        │ JS         │ State      │      │
│  │ (structure)│ (style)    │ (behavior) │ (UI state) │      │
│  └────────────┴────────────┴────────────┴────────────┘      │
│                        │                                      │
│                   API Client                                  │
│                   (fetch wrapper)                             │
└──────────────────────────────────────────────────────────────┘
                         │
                    REST API (JSON)
                         │
┌──────────────────────────────────────────────────────────────┐
│                      API LAYER (Flask)                        │
│  ┌────────────────────────────────────────────────┐          │
│  │  Endpoints (Resources)                         │          │
│  │  - /api/state       (GET current state)        │          │
│  │  - /api/config      (GET/POST config)          │          │
│  │  - /api/actions     (POST state transitions)   │          │
│  │  - /api/files       (GET/POST reference files) │          │
│  │  - /api/questions   (GET/POST Claude questions)│          │
│  └────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────┘
                         │
                    Service Layer
                         │
┌──────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                       │
│  ┌────────────┬────────────┬────────────┬────────────┐      │
│  │ State      │ Config     │ Process    │ File       │      │
│  │ Manager    │ Manager    │ Manager    │ Manager    │      │
│  └────────────┴────────────┴────────────┴────────────┘      │
└──────────────────────────────────────────────────────────────┘
                         │
                    Data Access
                         │
┌──────────────────────────────────────────────────────────────┐
│                     STORAGE LAYER                             │
│  ┌────────────────────────────────────────────────┐          │
│  │  State Store (state.json)                      │          │
│  │  {                                              │          │
│  │    "current_state": "planned",                 │          │
│  │    "phase": 1,                                 │          │
│  │    "total_phases": 8,                          │          │
│  │    "process_id": 12345,                        │          │
│  │    "last_updated": "2026-01-25T20:00:00"       │          │
│  │  }                                              │          │
│  └────────────────────────────────────────────────┘          │
│  ┌────────────────────────────────────────────────┐          │
│  │  Config (config/project-config.json)           │          │
│  └────────────────────────────────────────────────┘          │
│  ┌────────────────────────────────────────────────┐          │
│  │  Work Files (docs/, output/, etc.)             │          │
│  └────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────┘
```

---

## State Machine Design

### States

```
┌─────────────┐
│   RESET     │  Initial state, no project
└──────┬──────┘
       │ user clicks "configure"
       ▼
┌─────────────┐
│ CONFIGURED  │  Config saved, ready to plan
└──────┬──────┘
       │ POST /api/actions/generate-plan
       ▼
┌─────────────┐
│  PLANNING   │  Claude subprocess running
└──────┬──────┘
       │ plan generation complete
       ▼
┌─────────────┐
│  PLANNED    │  Plan exists, ready to execute
└──────┬──────┘
       │ POST /api/actions/execute
       ▼
┌─────────────┐
│ EXECUTING   │  Claude subprocess running phases
└──────┬──────┘
       │ questions detected
       ▼
┌─────────────┐
│ QUESTIONS   │  Waiting for user input
└──────┬──────┘
       │ POST /api/questions/answer
       ▼
┌─────────────┐
│ EXECUTING   │  Resume execution
└──────┬──────┘
       │ all phases complete
       ▼
┌─────────────┐
│  COMPLETE   │  Project finished
└─────────────┘
```

### State Transitions API

```
POST /api/actions
{
  "action": "generate_plan" | "execute" | "reset" | "continue"
}

Response:
{
  "success": true,
  "new_state": "planning",
  "message": "Plan generation started"
}
```

---

## Detailed Component Design

### 1. Frontend (conductor.html)

**Structure:**
```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="/static/conductor.css">
</head>
<body>
    <div id="app">
        <!-- Simple, semantic HTML -->
        <!-- No business logic -->
        <!-- No inline styles -->
    </div>

    <script src="/static/api-client.js"></script>
    <script src="/static/conductor.js"></script>
</body>
</html>
```

**Files:**
- `conductor.html` - Structure only (~200 lines)
- `static/conductor.css` - All styles (~300 lines)
- `static/api-client.js` - API wrapper (~100 lines)
- `static/conductor.js` - UI logic (~400 lines)

**Total: ~1000 lines split into 4 files (vs 1760 in one)**

---

### 2. API Layer (server/app.py)

**Simplified Endpoints:**

```python
# State Management
GET  /api/state              # Get current state
POST /api/actions            # Trigger state transition

# Configuration
GET  /api/config             # Get config
POST /api/config             # Save config

# File Management
GET  /api/files              # List reference files
POST /api/files/upload       # Upload files

# Questions
GET  /api/questions          # Get pending questions
POST /api/questions          # Submit answers

# System
GET  /api/system/status      # Claude CLI status
POST /api/system/reset       # Reset project
```

**Key Principles:**
- RESTful design
- JSON responses
- No state in memory
- Reads from state.json
- Returns current state with every response

---

### 3. State Manager (server/state_manager.py)

**New file** to centralize state:

```python
class StateManager:
    def __init__(self, state_file='state.json'):
        self.state_file = state_file

    def get_state(self) -> dict:
        """Get current state (thread-safe)"""

    def update_state(self, updates: dict):
        """Update state atomically"""

    def transition(self, action: str) -> dict:
        """Handle state transition"""

    def is_valid_transition(self, from_state: str, action: str) -> bool:
        """Validate state machine transitions"""
```

---

### 4. Process Manager (server/process_manager.py)

**New file** for subprocess management:

```python
class ProcessManager:
    def start_claude(self, command: str) -> int:
        """Start Claude subprocess, return PID"""

    def is_running(self, pid: int) -> bool:
        """Check if process is still running"""

    def stop(self, pid: int):
        """Gracefully stop process"""

    def get_output(self, pid: int) -> str:
        """Get subprocess output"""
```

---

## Migration Strategy

### Phase 1: Backend Refactor (1-2 hours)
1. Create `state_manager.py`
2. Create `process_manager.py`
3. Simplify `app.py` to use managers
4. Test API endpoints independently

### Phase 2: Frontend Rebuild (2-3 hours)
1. Create minimal `conductor.html` (structure only)
2. Create `conductor.css` (clean, no framework)
3. Create `api-client.js` (fetch wrapper)
4. Create `conductor.js` (UI logic)
5. Test incrementally

### Phase 3: Integration (1 hour)
1. Connect frontend to new backend
2. End-to-end testing
3. Remove old code

---

## File Structure

```
c:\NEOGOV\AIPM\
├── server/
│   ├── app.py                  # Flask routes (simplified)
│   ├── state_manager.py        # NEW - State machine
│   ├── process_manager.py      # NEW - Subprocess control
│   ├── config_manager.py       # NEW - Config handling
│   ├── templates/
│   │   └── conductor.html      # Structure only (~200 lines)
│   └── static/
│       ├── conductor.css       # All styles (~300 lines)
│       ├── api-client.js       # API wrapper (~100 lines)
│       └── conductor.js        # UI logic (~400 lines)
├── state.json                  # NEW - Single source of truth
├── config/
│   └── project-config.json     # User configuration
├── docs/planning/              # Claude's working files
└── output/                     # Generated files
```

---

## Next Steps

**Choose your path:**

1. **Full Rebuild** (Recommended)
   - Start fresh with clean architecture
   - Build backend managers first
   - Then rebuild frontend
   - ~4-6 hours total

2. **Incremental Refactor**
   - Extract managers from existing code
   - Keep current UI working
   - Gradually replace frontend
   - ~6-8 hours total

3. **Minimal Fix**
   - Just fix the CSS issue
   - Keep current architecture
   - ~30 min, but technical debt remains

**Which approach do you prefer?**
