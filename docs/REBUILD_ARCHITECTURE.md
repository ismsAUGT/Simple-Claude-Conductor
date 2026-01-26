# Simple Claude Conductor - Rebuild Architecture Specification

**Version:** 3.0
**Date:** 2026-01-25
**Status:** Design Phase (Revised)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problems We're Actually Solving](#problems-were-actually-solving)
3. [Architecture Principles](#architecture-principles)
4. [Permissions Model](#permissions-model)
5. [System Architecture](#system-architecture)
6. [State Management](#state-management)
7. [Process Management](#process-management)
8. [Frontend Architecture](#frontend-architecture)
9. [API Specification](#api-specification)
10. [File Structure](#file-structure)
11. [Implementation Plan](#implementation-plan)
12. [Risk Mitigation](#risk-mitigation)

---

## Executive Summary

### Goals

Build a **maintainable, cross-platform, reliable** web UI for Simple Claude Conductor that:

1. **Works on Windows** - Primary development platform, no Unix-only dependencies
2. **Single source of truth** - STATUS.md is THE state, not a secondary store
3. **Reliable process tracking** - Actually know if Claude is running
4. **Maintainable frontend** - Reactive UI without framework complexity
5. **Graceful error handling** - Recover from crashes, timeouts, user cancellation

### Non-Goals

- Multiple concurrent projects (single project at a time)
- Multi-user support (single user, single browser)
- Database integration (file-based is appropriate for this use case)
- Complex build tooling (no webpack, no transpiling)

### Key Changes from v2.0

| v2.0 Proposal | v3.0 Correction | Reason |
|---------------|-----------------|--------|
| `fcntl` file locking | `portalocker` library | fcntl doesn't exist on Windows |
| `state.json` + `STATUS.md` | STATUS.md with YAML frontmatter | Single source of truth |
| `cmd /c start` subprocess | Direct subprocess with `CREATE_NEW_CONSOLE` | Can't track PIDs through cmd start |
| 4-layer architecture | 3-layer architecture | YAGNI - separate API/Service layers unnecessary |
| Vanilla JS | Alpine.js (14KB) | Declarative reactivity without build complexity |
| Polling every 3s | Server-Sent Events (SSE) | Real-time updates, less overhead |
| 12-16 hour estimate | 28-40 hour estimate | Realistic with testing and edge cases |

---

## Problems We're Actually Solving

### 1. CSS Conflicts and Maintainability
- 700+ lines of inline CSS competing with DaisyUI
- oklch color functions with browser compatibility issues
- No clear ownership of styles

### 2. JavaScript Monolith
- 800+ lines of JS in a single `<script>` tag
- Global state scattered across functions
- Manual DOM manipulation everywhere
- No clear data flow

### 3. Subprocess Management
- Can't detect if Claude is actually running
- Can't detect crashes or hangs
- PID tracking is broken due to `cmd /c start` indirection

### 4. State Synchronization
- UI state derived from regex parsing STATUS.md
- No structured data format
- Fragile pattern matching

### 5. No Error Recovery
- No handling for Claude crashes
- No timeout detection
- No way to cancel operations

---

## Architecture Principles

### 1. Single Source of Truth

**STATUS.md is the only state store.** We add structured YAML frontmatter for machine parsing while keeping human-readable content below.

```markdown
---
state: executing
phase: 2
total_phases: 5
phase_name: "Implementing Core Features"
process_id: 12345
started_at: "2026-01-25T14:30:00"
error: null
---
# Project Status

**Last Updated**: 2026-01-25 14:35

## What To Do Next
...
```

### 2. Cross-Platform First

Every file operation, process management, and path handling must work on Windows. Test on Windows first, not as an afterthought.

### 3. Fail Gracefully

Every operation that can fail will fail. Design for:
- Claude crashes mid-execution
- User closes browser during operation
- Network interruption
- File permission errors
- Process hangs

### 4. Reactive UI, Minimal Framework

Use Alpine.js for declarative reactivity without:
- Build steps
- Node.js dependency
- Complex toolchain
- Large bundle size

### 5. Real-Time Updates

Server-Sent Events (SSE) for push updates instead of polling. Simpler than WebSockets, native browser support, automatic reconnection.

---

## Permissions Model

### Philosophy: Allowlist, Not Bypass

Claude Code has a permissions system that prompts users before performing potentially dangerous operations. There are two approaches to handling this:

1. **`--dangerously-skip-permissions`** - Bypasses ALL permission checks. Fast but risky.
2. **Curated Allowlist** - Pre-approve specific, safe operations. Secure and user-friendly.

**Simple Claude Conductor uses the allowlist approach.** This provides:
- Smooth UX (no constant permission prompts)
- Security (dangerous operations still blocked)
- Transparency (explicit list of what's allowed)

### Configuration Location

Permissions are configured in `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [ ... ],
    "deny": [ ... ]
  }
}
```

### Allowed Operations

#### Read-Only Tools (Always Allowed)
```json
"Read",
"Glob",
"Grep",
"WebSearch",
"WebFetch",
"Task"
```

These tools can't modify the system, so they're safe to allow unconditionally.

#### File Write/Edit (Scoped to Project)
```json
"Write(docs/**)",
"Write(src/**)",
"Write(output/**)",
"Write(server/**)",
"Write(STATUS.md)",
"Write(Questions_For_You.md)",
"Write(*.py)",
"Write(*.js)",
"Write(*.html)",
"Write(*.css)",
...
```

Write operations are allowed only:
- Within project directories (docs/, src/, output/, etc.)
- For specific file types (code, config, documentation)
- For conductor-specific files (STATUS.md, Questions_For_You.md)

#### Bash Commands (Specific Patterns)
```json
"Bash(python *)",
"Bash(pip install *)",
"Bash(npm run*)",
"Bash(git status*)",
"Bash(git add *)",
"Bash(git commit*)",
"Bash(mkdir *)",
"Bash(ls *)",
...
```

Only common, safe development commands are allowed. Each pattern is explicit.

### Denied Operations (Explicit Blocklist)

```json
"Bash(rm -rf /)",
"Bash(rm -rf ~)",
"Bash(git push --force*)",
"Bash(git reset --hard*)",
"Bash(sudo *)",
"Bash(curl * | bash)",
"Write(C:\\Windows\\*)",
"Write(C:\\Program Files*)"
```

Dangerous operations are explicitly blocked, even if they match an allow pattern.

### Why Not Bypass Permissions?

| Aspect | Bypass | Allowlist |
|--------|--------|-----------|
| Setup | One flag | Configure once |
| Security | None | Layered |
| User prompts | Zero | Zero (for allowed ops) |
| Accidental damage | Possible | Blocked |
| Audit trail | No | Clear list of capabilities |

The allowlist approach means:
- Users don't see permission prompts for normal development work
- Dangerous operations are still blocked
- The tool can't accidentally delete system files or force-push to git
- New users can trust the tool without understanding Claude's internals

### Permissions Required for Conductor

The conductor needs these permissions to function:

| Operation | Permission | Why |
|-----------|------------|-----|
| Read STATUS.md | `Read` | Check current state |
| Write STATUS.md | `Write(STATUS.md)` | Update progress |
| Read Questions_For_You.md | `Read` | Load questions |
| Write Questions_For_You.md | `Write(Questions_For_You.md)` | Save answers |
| Read/Write config | `Read`, `Write(config/**)` | Project configuration |
| Write output files | `Write(output/**)` | Generated artifacts |
| Write planning docs | `Write(docs/**)` | Task plan, findings |
| Run Python | `Bash(python *)` | Execute scripts |
| Git operations | `Bash(git *)` | Version control |

### Hooks for Additional Enforcement

Beyond permissions, hooks provide runtime guardrails:

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash|Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "bash .claude/hooks/pre-tool-guard.sh"
    }]
  }]
}
```

Hooks can:
- Block writes to protected branches
- Require domain understanding before planning
- Enforce quality gates before completion
- Remind about updating STATUS.md

### Updating Permissions

When adding new capabilities to the conductor:

1. Identify the minimum permissions needed
2. Add specific patterns to `.claude/settings.local.json`
3. Prefer narrow patterns (`Write(output/*.json)`) over broad ones (`Write(**)`)
4. Test that blocked operations are actually blocked
5. Document why each permission is needed

---

## System Architecture

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: PRESENTATION (Browser)                            │
│  ───────────────────────────────────────────────────────── │
│  Technology: HTML + Alpine.js + CSS                         │
│  Responsibility: Render UI, handle user interactions        │
│  Communication: HTTP REST + SSE for real-time updates       │
└─────────────────────────────────────────────────────────────┘
                            │
                    HTTP/JSON + SSE
                            │
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: APPLICATION (Flask)                               │
│  ───────────────────────────────────────────────────────── │
│  Technology: Flask + Python                                 │
│  Responsibility: API routes, business logic, orchestration  │
│  Contains: StateManager, ProcessManager, ConfigManager      │
└─────────────────────────────────────────────────────────────┘
                            │
                    File I/O + Subprocess
                            │
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: INFRASTRUCTURE (OS)                               │
│  ───────────────────────────────────────────────────────── │
│  Components: File system, Claude subprocess                 │
│  Files: STATUS.md, Questions_For_You.md, config files       │
└─────────────────────────────────────────────────────────────┘
```

### Why Three Layers, Not Four?

The v2.0 proposal separated API (routes) from Services (business logic). For a single-user desktop tool with ~15 endpoints, this adds:
- Extra files to maintain
- Extra indirection to debug
- No practical benefit (we're not swapping implementations)

Business logic lives in manager classes. Routes call managers directly.

---

## State Management

### State Machine

```
                                    ┌──────────────┐
                                    │              │
                                    ▼              │
┌───────┐    configure    ┌────────────┐          │
│ reset │───────────────▶│ configured │          │
└───────┘                 └────────────┘          │
    ▲                           │                 │
    │                    generate_plan            │
    │                           │                 │
    │                           ▼                 │
    │                    ┌────────────┐           │
    │                    │  planning  │───────────┤ error
    │                    └────────────┘           │
    │                           │                 │
    │                      (auto)                 │
    │                           │                 │
    │                           ▼                 │
    │     reset          ┌────────────┐           │
    ├───────────────────│  planned   │           │
    │                    └────────────┘           │
    │                           │                 │
    │                       execute               │
    │                           │                 │
    │                           ▼                 │
    │                    ┌────────────┐           │
    │  ┌────────────────│ executing  │───────────┤
    │  │                 └────────────┘           │
    │  │                   │   │   │              │
    │  │    ┌──────────────┘   │   └──────────┐  │
    │  │    │                  │              │  │
    │  │    ▼                  ▼              ▼  │
    │  │ ┌──────────┐   ┌────────────┐  ┌───────┴──┐
    │  │ │ questions│   │  complete  │  │  error   │
    │  │ └──────────┘   └────────────┘  └──────────┘
    │  │       │              │               │
    │  │    answer            │               │
    │  │       │              │               │
    │  │       ▼              │               │
    │  └──▶executing          │               │
    │                         │               │
    └─────────────────────────┴───────────────┘
                    reset
```

### State Definitions

| State | Description | Available Actions | Auto-Transitions |
|-------|-------------|-------------------|------------------|
| `reset` | Fresh start, no project configured | `configure` | - |
| `configured` | Config saved, ready to plan | `generate_plan`, `reset` | - |
| `planning` | Claude is generating plan | `cancel` | → `planned`, → `error` |
| `planned` | Plan exists, ready to execute | `execute`, `reset` | - |
| `executing` | Claude is executing phases | `cancel` | → `questions`, → `complete`, → `error` |
| `questions` | Claude needs user input | `answer`, `skip`, `cancel` | - |
| `complete` | All phases finished | `reset` | - |
| `error` | Something went wrong | `retry`, `reset` | - |

### Transition Rules

```python
TRANSITIONS = {
    'reset': {
        'configure': 'configured'
    },
    'configured': {
        'generate_plan': 'planning',
        'reset': 'reset'
    },
    'planning': {
        'plan_complete': 'planned',  # Auto: detected from STATUS.md
        'cancel': 'configured',
        'error': 'error'
    },
    'planned': {
        'execute': 'executing',
        'reset': 'reset'
    },
    'executing': {
        'questions_detected': 'questions',  # Auto: detected from Questions_For_You.md
        'phase_complete': 'executing',      # Auto: stay in executing, update phase
        'all_complete': 'complete',         # Auto: all phases done
        'cancel': 'planned',
        'error': 'error'
    },
    'questions': {
        'answer': 'executing',
        'skip': 'executing',
        'cancel': 'planned'
    },
    'complete': {
        'reset': 'reset'
    },
    'error': {
        'retry': 'previous_state',  # Return to state before error
        'reset': 'reset'
    }
}
```

### STATUS.md Format

```markdown
---
# Machine-readable state (YAML frontmatter)
state: executing
phase: 2
total_phases: 5
phase_name: "Implementing Core Features"
process_id: 12345
process_start: "2026-01-25T14:30:00"
last_updated: "2026-01-25T14:35:22"
error: null
previous_state: null
---
# Project Status: My Project

**Last Updated**: 2026-01-25 14:35

---

## What To Do Next

**Status: Working on Phase 2 of 5: Implementing Core Features**

Check back for updates, or watch the terminal window for Claude's progress.

---

## Quick Status

| Item | Status |
|------|--------|
| Plan Generated | Yes |
| Current Phase | Phase 2 of 5: Implementing Core Features |
| Phases Completed | 1 / 5 |

---

## Progress Log

- [14:30] Started Phase 2: Implementing Core Features
- [14:25] Completed Phase 1: Project Setup
- [14:20] Plan generation complete (5 phases)
- [14:15] Started plan generation
```

### Parsing STATUS.md

```python
import yaml
import re

def parse_status_file(content: str) -> dict:
    """
    Parse STATUS.md with YAML frontmatter.

    Returns structured state even if frontmatter is missing or malformed.
    """
    # Default state
    state = {
        'state': 'reset',
        'phase': 0,
        'total_phases': 0,
        'phase_name': None,
        'process_id': None,
        'process_start': None,
        'last_updated': None,
        'error': None,
        'previous_state': None
    }

    # Try to parse YAML frontmatter
    frontmatter_match = re.match(r'^---\n(.+?)\n---', content, re.DOTALL)
    if frontmatter_match:
        try:
            parsed = yaml.safe_load(frontmatter_match.group(1))
            if isinstance(parsed, dict):
                state.update(parsed)
        except yaml.YAMLError:
            pass  # Fall back to defaults

    return state
```

---

## Process Management

### The Problem with `cmd /c start`

Current code:
```python
subprocess.Popen(['cmd', '/c', 'start', 'cmd', '/k', 'claude -p "Generate plan"'])
```

This creates a process chain:
1. Python calls cmd.exe (PID 1000)
2. cmd.exe calls `start` which spawns new console (PID 1001)
3. New console runs claude (PID 1002)
4. **cmd.exe (PID 1000) exits immediately**

We only have reference to PID 1000, which is already dead. We can never track Claude.

### The Solution: Direct Subprocess

```python
import subprocess
import sys
import threading
import queue

class ProcessManager:
    """
    Manages Claude subprocess with proper tracking.

    Key features:
    - Direct subprocess (no cmd indirection)
    - Output capture for logging
    - Proper Windows console handling
    - Timeout detection
    - Crash detection
    """

    def __init__(self):
        self.process = None
        self.output_queue = queue.Queue()
        self.output_thread = None
        self._lock = threading.Lock()

    def start_claude(self, prompt: str, working_dir: str) -> int:
        """
        Start Claude with given prompt.

        Args:
            prompt: Command to send to Claude
            working_dir: Project root directory

        Returns:
            Process ID

        Raises:
            RuntimeError: If Claude is already running
        """
        with self._lock:
            if self.is_running():
                raise RuntimeError("Claude is already running")

            # Build command
            cmd = ['claude', '-p', prompt]

            # Platform-specific subprocess creation
            kwargs = {
                'cwd': working_dir,
                'stdout': subprocess.PIPE,
                'stderr': subprocess.STDOUT,
                'text': True,
                'bufsize': 1,  # Line buffered
            }

            if sys.platform == 'win32':
                # CREATE_NEW_CONSOLE: Claude gets its own console window
                # User can see Claude's output directly
                kwargs['creationflags'] = subprocess.CREATE_NEW_CONSOLE

            self.process = subprocess.Popen(cmd, **kwargs)

            # Start output reader thread
            self.output_thread = threading.Thread(
                target=self._read_output,
                daemon=True
            )
            self.output_thread.start()

            return self.process.pid

    def _read_output(self):
        """Read subprocess output in background thread."""
        try:
            for line in self.process.stdout:
                self.output_queue.put(line.rstrip())
        except Exception:
            pass

    def is_running(self) -> bool:
        """Check if Claude subprocess is actually running."""
        if self.process is None:
            return False

        # poll() returns None if still running, return code if finished
        return self.process.poll() is None

    def get_return_code(self) -> int | None:
        """Get process return code (None if still running)."""
        if self.process is None:
            return None
        return self.process.poll()

    def get_recent_output(self, max_lines: int = 50) -> list[str]:
        """Get recent output lines (non-blocking)."""
        lines = []
        while not self.output_queue.empty() and len(lines) < max_lines:
            try:
                lines.append(self.output_queue.get_nowait())
            except queue.Empty:
                break
        return lines

    def stop(self, timeout: float = 10.0) -> bool:
        """
        Stop Claude gracefully.

        Args:
            timeout: Seconds to wait before force kill

        Returns:
            True if stopped cleanly, False if force killed
        """
        if not self.is_running():
            return True

        with self._lock:
            # Try graceful termination first
            self.process.terminate()

            try:
                self.process.wait(timeout=timeout)
                return True
            except subprocess.TimeoutExpired:
                # Force kill
                self.process.kill()
                self.process.wait()
                return False

    def get_runtime_seconds(self) -> float | None:
        """Get how long the process has been running."""
        if self.process is None:
            return None

        # This requires tracking start time separately
        # or using psutil for process creation time
        return None  # Implement with psutil if needed


# Singleton instance
process_manager = ProcessManager()
```

### Timeout Detection

```python
import time
from datetime import datetime, timedelta

class TimeoutMonitor:
    """
    Monitor for stuck/hung processes.

    Detects when Claude hasn't updated STATUS.md for too long.
    """

    STALL_THRESHOLD = timedelta(minutes=5)
    HARD_TIMEOUT = timedelta(minutes=30)

    def __init__(self, status_file: str):
        self.status_file = status_file
        self.last_modified = None
        self.process_start = None

    def check(self) -> dict:
        """
        Check for timeout conditions.

        Returns:
            {
                'stalled': bool,      # No updates for STALL_THRESHOLD
                'timed_out': bool,    # Running longer than HARD_TIMEOUT
                'last_update': datetime,
                'runtime': timedelta
            }
        """
        now = datetime.now()

        # Get STATUS.md modification time
        try:
            mtime = os.path.getmtime(self.status_file)
            last_update = datetime.fromtimestamp(mtime)
        except OSError:
            last_update = None

        # Calculate runtime
        runtime = None
        if self.process_start:
            runtime = now - self.process_start

        return {
            'stalled': last_update and (now - last_update) > self.STALL_THRESHOLD,
            'timed_out': runtime and runtime > self.HARD_TIMEOUT,
            'last_update': last_update,
            'runtime': runtime
        }
```

---

## Frontend Architecture

### Why Alpine.js?

| Approach | Bundle Size | Build Required | Learning Curve | Reactivity |
|----------|-------------|----------------|----------------|------------|
| Vanilla JS | 0 KB | No | Low | Manual |
| Alpine.js | 14 KB | No | Low | Declarative |
| Petite Vue | 6 KB | No | Medium | Declarative |
| React | 130+ KB | Yes | High | Declarative |
| Vue | 90+ KB | Yes | Medium | Declarative |

Alpine.js gives us:
- Declarative data binding (no manual DOM updates)
- Component-like structure
- Event handling
- Transitions/animations
- No build step (CDN script tag)

### File Structure

```
server/
├── templates/
│   └── conductor.html      # HTML structure with Alpine.js directives (~250 lines)
└── static/
    ├── css/
    │   └── conductor.css   # All styles (~350 lines)
    └── js/
        ├── api.js          # API client + SSE handling (~100 lines)
        ├── state.js        # State management (~150 lines)
        └── app.js          # Alpine.js components (~200 lines)
```

### HTML Structure (conductor.html)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Claude Conductor</title>
    <link rel="stylesheet" href="/static/css/conductor.css">
    <!-- Alpine.js from CDN - no build step needed -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body>
    <!-- Main app container with Alpine.js -->
    <div x-data="conductorApp()" x-init="init()" class="container">

        <!-- Header -->
        <header>
            <h1>Simple Claude Conductor</h1>
            <p>Build software projects with AI assistance</p>
        </header>

        <!-- Connection status banner -->
        <div x-show="!connected" class="banner banner--warning">
            <span>Reconnecting to server...</span>
        </div>

        <!-- Error banner -->
        <div x-show="state.state === 'error'" class="banner banner--error">
            <strong>Error:</strong> <span x-text="state.error"></span>
            <button @click="retry()" class="btn btn--small">Retry</button>
            <button @click="reset()" class="btn btn--small btn--secondary">Reset</button>
        </div>

        <!-- Stage progress indicator -->
        <nav class="stages" aria-label="Progress">
            <template x-for="(stage, index) in stages" :key="stage.id">
                <div class="stage"
                     :class="{
                         'stage--complete': isStageComplete(stage.id),
                         'stage--active': isStageActive(stage.id)
                     }">
                    <div class="stage__dot" x-text="index + 1"></div>
                    <div class="stage__label" x-text="stage.label"></div>
                </div>
            </template>
        </nav>

        <!-- Main status card -->
        <section class="card">
            <header class="card__header">
                <span class="status-dot" :class="statusDotClass"></span>
                <h2 x-text="statusTitle"></h2>
            </header>

            <!-- Activity message -->
            <div class="activity-box" :class="{ 'activity-box--waiting': state.state === 'questions' }">
                <p x-text="state.activity || 'Ready to start'"></p>
            </div>

            <!-- Progress bar (when executing) -->
            <div x-show="state.total_phases > 0" class="progress">
                <div class="progress__bar">
                    <div class="progress__fill" :style="{ width: progressPercent + '%' }"></div>
                </div>
                <div class="progress__info">
                    <span x-text="phaseLabel"></span>
                    <span x-text="progressPercent + '%'"></span>
                </div>
            </div>

            <!-- Action buttons -->
            <div class="actions">
                <button @click="performAction()"
                        :disabled="!canPerformAction"
                        class="btn btn--primary">
                    <span x-show="loading" class="spinner"></span>
                    <span x-text="actionButtonText"></span>
                </button>

                <button x-show="canCancel"
                        @click="cancel()"
                        class="btn btn--secondary">
                    Cancel
                </button>

                <button @click="openOutput()" class="btn btn--secondary">
                    Open Output
                </button>
            </div>
        </section>

        <!-- Configuration card -->
        <section class="card" x-show="showConfig">
            <header class="card__header card__header--collapsible" @click="configExpanded = !configExpanded">
                <h2>Configure Project</h2>
                <span class="chevron" :class="{ 'chevron--down': configExpanded }"></span>
            </header>

            <div x-show="configExpanded" x-collapse>
                <form @submit.prevent="saveConfig()">
                    <div class="form-group">
                        <label for="project-name">Project Name</label>
                        <input type="text"
                               id="project-name"
                               x-model="config.projectName"
                               required>
                    </div>

                    <div class="form-group">
                        <label for="project-description">What do you want to build?</label>
                        <textarea id="project-description"
                                  x-model="config.projectDescription"
                                  rows="4"
                                  required></textarea>
                        <small>Be specific about features and requirements</small>
                    </div>

                    <div class="form-group">
                        <label for="default-model">Default Model</label>
                        <select id="default-model" x-model="config.defaultModel">
                            <option value="haiku">Haiku (Fastest)</option>
                            <option value="sonnet">Sonnet (Balanced)</option>
                            <option value="opus">Opus (Most Capable)</option>
                        </select>
                    </div>

                    <div class="actions">
                        <button type="submit" class="btn btn--primary">Save Configuration</button>
                    </div>
                </form>
            </div>
        </section>

        <!-- Questions card -->
        <section class="card card--questions" x-show="state.state === 'questions'">
            <header class="card__header">
                <h2>Claude Has Questions</h2>
            </header>

            <p class="card__subtitle">Please answer to continue, or skip to let Claude decide.</p>

            <template x-for="question in questions" :key="question.number">
                <div class="question">
                    <div class="question__topic" x-text="'Question ' + question.number + ': ' + question.topic"></div>
                    <div class="question__text" x-text="question.question"></div>
                    <textarea class="question__input"
                              x-model="question.answer"
                              placeholder="Your answer..."></textarea>
                </div>
            </template>

            <div class="actions">
                <button @click="submitAnswers()" class="btn btn--primary">Submit Answers</button>
                <button @click="skipQuestions()" class="btn btn--secondary">Skip - Let Claude Decide</button>
            </div>
        </section>

        <!-- System status card -->
        <section class="card">
            <header class="card__header">
                <h2>System Status</h2>
            </header>

            <div class="info-grid">
                <div class="info-row">
                    <span class="info-label">Claude Installed</span>
                    <span x-text="system.installed ? 'Yes' : 'No'"></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Logged In</span>
                    <span x-text="system.email || 'Not logged in'"></span>
                </div>
                <div class="info-row">
                    <span class="info-label">Process</span>
                    <span x-text="state.process_id ? 'Running (PID ' + state.process_id + ')' : 'Idle'"></span>
                </div>
            </div>
        </section>

        <!-- Footer -->
        <footer>
            Simple Claude Conductor v2.0 |
            <a href="#" @click.prevent="refresh()">Refresh</a>
        </footer>
    </div>

    <!-- Application scripts -->
    <script src="/static/js/api.js"></script>
    <script src="/static/js/state.js"></script>
    <script src="/static/js/app.js"></script>
</body>
</html>
```

### API Client (api.js)

```javascript
/**
 * API Client with Server-Sent Events support
 */
class APIClient {
    constructor(baseURL = '/api') {
        this.baseURL = baseURL;
        this.eventSource = null;
        this.onStateUpdate = null;
        this.onConnectionChange = null;
    }

    /**
     * Start SSE connection for real-time updates
     */
    connectSSE() {
        if (this.eventSource) {
            this.eventSource.close();
        }

        this.eventSource = new EventSource(`${this.baseURL}/events`);

        this.eventSource.onopen = () => {
            console.log('SSE connected');
            if (this.onConnectionChange) {
                this.onConnectionChange(true);
            }
        };

        this.eventSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (this.onStateUpdate) {
                    this.onStateUpdate(data);
                }
            } catch (e) {
                console.error('Failed to parse SSE data:', e);
            }
        };

        this.eventSource.onerror = () => {
            console.log('SSE disconnected, reconnecting...');
            if (this.onConnectionChange) {
                this.onConnectionChange(false);
            }
            // EventSource auto-reconnects
        };
    }

    /**
     * Close SSE connection
     */
    disconnect() {
        if (this.eventSource) {
            this.eventSource.close();
            this.eventSource = null;
        }
    }

    /**
     * Generic fetch wrapper with error handling
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            ...options,
        };

        if (config.body && typeof config.body === 'object') {
            config.body = JSON.stringify(config.body);
        }

        const response = await fetch(url, config);

        if (!response.ok) {
            const error = await response.json().catch(() => ({ error: response.statusText }));
            throw new Error(error.error || `HTTP ${response.status}`);
        }

        return response.json();
    }

    // Convenience methods
    get(endpoint) {
        return this.request(endpoint);
    }

    post(endpoint, data) {
        return this.request(endpoint, { method: 'POST', body: data });
    }

    // API endpoints
    getState() { return this.get('/state'); }
    getConfig() { return this.get('/config'); }
    saveConfig(config) { return this.post('/config', config); }
    getQuestions() { return this.get('/questions'); }
    submitAnswers(answers) { return this.post('/questions/answer', { answers }); }
    skipQuestions() { return this.post('/questions/skip', {}); }

    // Actions
    generatePlan() { return this.post('/actions/generate-plan', {}); }
    executePlan() { return this.post('/actions/execute', {}); }
    continueExecution() { return this.post('/actions/continue', {}); }
    cancel() { return this.post('/actions/cancel', {}); }
    reset() { return this.post('/actions/reset', {}); }
    retry() { return this.post('/actions/retry', {}); }

    // System
    checkSystem() { return this.get('/system/status'); }
    openOutput() { return this.post('/system/open-output', {}); }
}

// Export singleton
const api = new APIClient();
```

### Alpine.js App (app.js)

```javascript
/**
 * Main Alpine.js application
 */
function conductorApp() {
    return {
        // Connection state
        connected: true,
        loading: false,

        // Application state (from server)
        state: {
            state: 'reset',
            phase: 0,
            total_phases: 0,
            phase_name: null,
            process_id: null,
            error: null,
            activity: ''
        },

        // Configuration
        config: {
            projectName: '',
            projectDescription: '',
            defaultModel: 'sonnet',
            askQuestions: true
        },
        configExpanded: true,

        // Questions
        questions: [],

        // System status
        system: {
            installed: false,
            email: null
        },

        // Stage definitions
        stages: [
            { id: 'reset', label: 'Start' },
            { id: 'configured', label: 'Configure' },
            { id: 'planning', label: 'Plan' },
            { id: 'executing', label: 'Execute' },
            { id: 'complete', label: 'Complete' }
        ],

        /**
         * Initialize the application
         */
        async init() {
            // Load initial state
            await this.loadState();
            await this.loadConfig();
            await this.checkSystem();

            // Connect to SSE for real-time updates
            api.onStateUpdate = (data) => this.handleStateUpdate(data);
            api.onConnectionChange = (connected) => this.connected = connected;
            api.connectSSE();
        },

        /**
         * Handle state update from SSE
         */
        handleStateUpdate(data) {
            this.state = { ...this.state, ...data };

            // Auto-load questions when in questions state
            if (this.state.state === 'questions') {
                this.loadQuestions();
            }
        },

        /**
         * Load current state from server
         */
        async loadState() {
            try {
                this.state = await api.getState();
            } catch (e) {
                console.error('Failed to load state:', e);
            }
        },

        /**
         * Load configuration
         */
        async loadConfig() {
            try {
                const config = await api.getConfig();
                if (config.projectName) {
                    this.config = config;
                    this.configExpanded = false; // Collapse if already configured
                }
            } catch (e) {
                console.error('Failed to load config:', e);
            }
        },

        /**
         * Save configuration
         */
        async saveConfig() {
            this.loading = true;
            try {
                await api.saveConfig(this.config);
                this.configExpanded = false;
                await this.loadState();
            } catch (e) {
                alert('Failed to save configuration: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Check system status
         */
        async checkSystem() {
            try {
                this.system = await api.checkSystem();
            } catch (e) {
                console.error('Failed to check system:', e);
            }
        },

        /**
         * Load questions
         */
        async loadQuestions() {
            try {
                const data = await api.getQuestions();
                this.questions = data.questions || [];
            } catch (e) {
                console.error('Failed to load questions:', e);
            }
        },

        /**
         * Perform the primary action based on current state
         */
        async performAction() {
            this.loading = true;
            try {
                switch (this.state.state) {
                    case 'reset':
                    case 'configured':
                        await api.generatePlan();
                        break;
                    case 'planned':
                        await api.executePlan();
                        break;
                    case 'questions':
                        await this.submitAnswers();
                        return; // submitAnswers handles loading state
                    case 'complete':
                        await api.reset();
                        this.configExpanded = true;
                        break;
                    case 'error':
                        await api.retry();
                        break;
                }
            } catch (e) {
                alert('Action failed: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Submit question answers
         */
        async submitAnswers() {
            this.loading = true;
            try {
                const answers = {};
                this.questions.forEach(q => {
                    answers[q.number] = q.answer || '(No answer provided)';
                });
                await api.submitAnswers(answers);
            } catch (e) {
                alert('Failed to submit answers: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Skip questions
         */
        async skipQuestions() {
            if (!confirm('Skip answering questions? Claude will make assumptions.')) {
                return;
            }
            this.loading = true;
            try {
                await api.skipQuestions();
            } catch (e) {
                alert('Failed to skip questions: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Cancel current operation
         */
        async cancel() {
            if (!confirm('Cancel the current operation?')) {
                return;
            }
            try {
                await api.cancel();
            } catch (e) {
                alert('Failed to cancel: ' + e.message);
            }
        },

        /**
         * Reset project
         */
        async reset() {
            if (!confirm('Reset project? Current work will be archived.')) {
                return;
            }
            try {
                await api.reset();
                this.configExpanded = true;
            } catch (e) {
                alert('Failed to reset: ' + e.message);
            }
        },

        /**
         * Retry after error
         */
        async retry() {
            try {
                await api.retry();
            } catch (e) {
                alert('Failed to retry: ' + e.message);
            }
        },

        /**
         * Refresh state manually
         */
        async refresh() {
            await this.loadState();
            await this.checkSystem();
        },

        /**
         * Open output folder
         */
        async openOutput() {
            try {
                await api.openOutput();
            } catch (e) {
                alert('Failed to open output folder: ' + e.message);
            }
        },

        // Computed properties

        get statusDotClass() {
            const classes = {
                'complete': 'status-dot--success',
                'executing': 'status-dot--warning',
                'planning': 'status-dot--warning',
                'planned': 'status-dot--success',
                'questions': 'status-dot--warning',
                'error': 'status-dot--error'
            };
            return classes[this.state.state] || 'status-dot--neutral';
        },

        get statusTitle() {
            const titles = {
                'reset': 'Ready to Start',
                'configured': 'Ready to Generate Plan',
                'planning': 'Generating Plan...',
                'planned': 'Plan Ready',
                'executing': 'Executing...',
                'questions': 'Questions Pending',
                'complete': 'Project Complete!',
                'error': 'Error Occurred'
            };
            return titles[this.state.state] || 'Unknown State';
        },

        get actionButtonText() {
            if (this.loading) return 'Working...';
            const texts = {
                'reset': 'Generate Plan',
                'configured': 'Generate Plan',
                'planning': 'Planning...',
                'planned': 'Execute Plan',
                'executing': 'Executing...',
                'questions': 'Submit Answers',
                'complete': 'Start New Project',
                'error': 'Retry'
            };
            return texts[this.state.state] || 'Action';
        },

        get canPerformAction() {
            if (this.loading) return false;
            // Can't act during auto-transition states
            return !['planning', 'executing'].includes(this.state.state);
        },

        get canCancel() {
            return ['planning', 'executing'].includes(this.state.state);
        },

        get showConfig() {
            return ['reset', 'configured', 'planned', 'complete'].includes(this.state.state);
        },

        get progressPercent() {
            if (this.state.total_phases === 0) return 0;
            return Math.round((this.state.phase / this.state.total_phases) * 100);
        },

        get phaseLabel() {
            if (!this.state.phase_name) {
                return `Phase ${this.state.phase} of ${this.state.total_phases}`;
            }
            return `Phase ${this.state.phase} of ${this.state.total_phases}: ${this.state.phase_name}`;
        },

        /**
         * Check if a stage is complete
         */
        isStageComplete(stageId) {
            const order = ['reset', 'configured', 'planning', 'planned', 'executing', 'complete'];
            const currentIndex = order.indexOf(this.state.state);
            const stageIndex = order.indexOf(stageId);

            // Special cases
            if (this.state.state === 'error') return false;
            if (this.state.state === 'questions') {
                // In questions state, executing is active, not complete
                return stageIndex < order.indexOf('executing');
            }

            return stageIndex < currentIndex;
        },

        /**
         * Check if a stage is active
         */
        isStageActive(stageId) {
            const stateToStage = {
                'reset': 'reset',
                'configured': 'configured',
                'planning': 'planning',
                'planned': 'planning',
                'executing': 'executing',
                'questions': 'executing',
                'complete': 'complete',
                'error': null
            };
            return stateToStage[this.state.state] === stageId;
        }
    };
}
```

### CSS (conductor.css)

```css
/**
 * Simple Claude Conductor Styles
 *
 * Design tokens at top, then components.
 * Mobile-first responsive design.
 * No framework dependencies.
 */

/* ============ Design Tokens ============ */

:root {
    /* Colors - using standard hex for compatibility */
    --color-primary: #ff6b35;
    --color-primary-dark: #e55a2b;
    --color-success: #22c55e;
    --color-warning: #f59e0b;
    --color-error: #ef4444;
    --color-neutral: #6b7280;

    /* Background colors */
    --bg-body: #111827;
    --bg-card: #1f2937;
    --bg-input: #374151;
    --bg-hover: #374151;

    /* Text colors */
    --text-primary: #f9fafb;
    --text-secondary: #9ca3af;
    --text-muted: #6b7280;

    /* Borders */
    --border-color: #374151;
    --border-radius: 8px;
    --border-radius-lg: 12px;

    /* Spacing */
    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;
    --space-xl: 2rem;

    /* Typography */
    --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-size-sm: 0.875rem;
    --font-size-base: 1rem;
    --font-size-lg: 1.125rem;
    --font-size-xl: 1.5rem;

    /* Transitions */
    --transition-fast: 150ms ease;
    --transition-normal: 250ms ease;
}

/* ============ Base Styles ============ */

*, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: var(--font-family);
    font-size: var(--font-size-base);
    line-height: 1.6;
    color: var(--text-primary);
    background: var(--bg-body);
    min-height: 100vh;
}

/* ============ Layout ============ */

.container {
    max-width: 800px;
    margin: 0 auto;
    padding: var(--space-lg);
}

header {
    text-align: center;
    margin-bottom: var(--space-xl);
}

header h1 {
    font-size: var(--font-size-xl);
    color: var(--color-primary);
    margin-bottom: var(--space-xs);
}

header p {
    color: var(--text-secondary);
}

footer {
    text-align: center;
    padding: var(--space-xl);
    color: var(--text-muted);
    font-size: var(--font-size-sm);
}

footer a {
    color: var(--color-primary);
    text-decoration: none;
}

footer a:hover {
    text-decoration: underline;
}

/* ============ Cards ============ */

.card {
    background: var(--bg-card);
    border-radius: var(--border-radius-lg);
    border: 1px solid var(--border-color);
    padding: var(--space-lg);
    margin-bottom: var(--space-lg);
}

.card__header {
    display: flex;
    align-items: center;
    gap: var(--space-sm);
    margin-bottom: var(--space-md);
}

.card__header h2 {
    font-size: var(--font-size-lg);
    font-weight: 600;
}

.card__header--collapsible {
    cursor: pointer;
    user-select: none;
}

.card__header--collapsible:hover {
    color: var(--color-primary);
}

.card__subtitle {
    color: var(--text-secondary);
    margin-bottom: var(--space-md);
}

.card--questions {
    border-left: 4px solid var(--color-warning);
}

/* ============ Banners ============ */

.banner {
    padding: var(--space-md);
    border-radius: var(--border-radius);
    margin-bottom: var(--space-lg);
    display: flex;
    align-items: center;
    gap: var(--space-md);
}

.banner--warning {
    background: rgba(245, 158, 11, 0.2);
    border: 1px solid var(--color-warning);
}

.banner--error {
    background: rgba(239, 68, 68, 0.2);
    border: 1px solid var(--color-error);
}

/* ============ Stage Progress ============ */

.stages {
    display: flex;
    justify-content: space-between;
    margin-bottom: var(--space-xl);
    padding: 0 var(--space-md);
}

.stage {
    display: flex;
    flex-direction: column;
    align-items: center;
    flex: 1;
    position: relative;
}

/* Connector line between stages */
.stage:not(:last-child)::after {
    content: '';
    position: absolute;
    top: 15px;
    left: 50%;
    width: 100%;
    height: 2px;
    background: var(--border-color);
    z-index: 0;
}

.stage--complete:not(:last-child)::after,
.stage--active:not(:last-child)::after {
    background: var(--color-primary);
}

.stage__dot {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: var(--border-color);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: var(--font-size-sm);
    font-weight: 600;
    color: var(--text-muted);
    position: relative;
    z-index: 1;
    transition: all var(--transition-normal);
}

.stage--active .stage__dot {
    background: var(--color-primary);
    color: white;
}

.stage--complete .stage__dot {
    background: var(--color-success);
    color: white;
}

.stage__label {
    margin-top: var(--space-sm);
    font-size: 0.75rem;
    color: var(--text-muted);
}

.stage--active .stage__label {
    color: var(--color-primary);
    font-weight: 500;
}

/* ============ Status Elements ============ */

.status-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: var(--color-neutral);
}

.status-dot--success { background: var(--color-success); }
.status-dot--warning {
    background: var(--color-warning);
    animation: pulse 2s infinite;
}
.status-dot--error { background: var(--color-error); }
.status-dot--neutral { background: var(--color-neutral); }

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

.activity-box {
    background: var(--bg-input);
    border-radius: var(--border-radius);
    padding: var(--space-md);
    margin-bottom: var(--space-md);
    border-left: 3px solid var(--color-primary);
}

.activity-box--waiting {
    border-left-color: var(--color-warning);
}

/* ============ Progress Bar ============ */

.progress {
    margin-bottom: var(--space-md);
}

.progress__bar {
    height: 8px;
    background: var(--border-color);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: var(--space-sm);
}

.progress__fill {
    height: 100%;
    background: var(--color-primary);
    border-radius: 4px;
    transition: width var(--transition-normal);
}

.progress__info {
    display: flex;
    justify-content: space-between;
    font-size: var(--font-size-sm);
    color: var(--text-secondary);
}

/* ============ Buttons ============ */

.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--space-sm);
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: var(--border-radius);
    font-size: var(--font-size-base);
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
}

.btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.btn--primary {
    background: var(--color-primary);
    color: white;
}

.btn--primary:hover:not(:disabled) {
    background: var(--color-primary-dark);
}

.btn--secondary {
    background: var(--bg-input);
    color: var(--text-primary);
    border: 1px solid var(--border-color);
}

.btn--secondary:hover:not(:disabled) {
    background: var(--bg-hover);
}

.btn--small {
    padding: 0.5rem 1rem;
    font-size: var(--font-size-sm);
}

.actions {
    display: flex;
    gap: var(--space-md);
    flex-wrap: wrap;
}

/* ============ Forms ============ */

.form-group {
    margin-bottom: var(--space-md);
}

.form-group label {
    display: block;
    margin-bottom: var(--space-sm);
    font-weight: 500;
}

.form-group input,
.form-group textarea,
.form-group select {
    width: 100%;
    padding: 0.75rem;
    background: var(--bg-input);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    color: var(--text-primary);
    font-size: var(--font-size-base);
    font-family: inherit;
    transition: border-color var(--transition-fast);
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
    outline: none;
    border-color: var(--color-primary);
}

.form-group textarea {
    resize: vertical;
    min-height: 100px;
}

.form-group small {
    display: block;
    margin-top: var(--space-xs);
    color: var(--text-muted);
    font-size: var(--font-size-sm);
}

.form-group select option {
    background: var(--bg-card);
}

/* ============ Questions ============ */

.question {
    background: var(--bg-input);
    border-radius: var(--border-radius);
    padding: var(--space-md);
    margin-bottom: var(--space-md);
}

.question__topic {
    font-weight: 600;
    color: var(--color-primary);
    margin-bottom: var(--space-sm);
    font-size: var(--font-size-sm);
}

.question__text {
    margin-bottom: var(--space-md);
    line-height: 1.5;
}

.question__input {
    width: 100%;
    padding: 0.75rem;
    background: var(--bg-body);
    border: 1px solid var(--border-color);
    border-radius: var(--border-radius);
    color: var(--text-primary);
    font-family: inherit;
    resize: vertical;
    min-height: 60px;
}

.question__input:focus {
    outline: none;
    border-color: var(--color-primary);
}

/* ============ Info Grid ============ */

.info-grid {
    display: flex;
    flex-direction: column;
}

.info-row {
    display: flex;
    justify-content: space-between;
    padding: var(--space-sm) 0;
    border-bottom: 1px solid var(--border-color);
}

.info-row:last-child {
    border-bottom: none;
}

.info-label {
    color: var(--text-secondary);
}

/* ============ Utilities ============ */

.spinner {
    width: 16px;
    height: 16px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: white;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

.chevron {
    transition: transform var(--transition-fast);
}

.chevron--down {
    transform: rotate(180deg);
}

[x-cloak] {
    display: none !important;
}

/* ============ Responsive ============ */

@media (max-width: 600px) {
    .container {
        padding: var(--space-md);
    }

    .stages {
        padding: 0;
    }

    .stage__label {
        font-size: 0.65rem;
    }

    .actions {
        flex-direction: column;
    }

    .btn {
        width: 100%;
    }
}
```

---

## API Specification

### Server-Sent Events

#### GET /api/events

Server-Sent Events endpoint for real-time state updates.

**Response:** SSE stream with JSON data

```
event: message
data: {"state": "executing", "phase": 2, "total_phases": 5, ...}

event: message
data: {"state": "executing", "phase": 3, "total_phases": 5, ...}
```

**Implementation:**

```python
from flask import Response
import time

@app.route('/api/events')
def events():
    def generate():
        while True:
            state = state_manager.get_state()
            yield f"data: {json.dumps(state)}\n\n"
            time.sleep(1)

    return Response(
        generate(),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
        }
    )
```

### REST Endpoints

#### GET /api/state

Get current application state.

**Response:**
```json
{
    "state": "executing",
    "phase": 2,
    "total_phases": 5,
    "phase_name": "Implementing Core Features",
    "process_id": 12345,
    "process_start": "2026-01-25T14:30:00",
    "last_updated": "2026-01-25T14:35:22",
    "error": null,
    "activity": "Working on Phase 2..."
}
```

#### POST /api/actions/generate-plan

Start plan generation.

**Response:**
```json
{
    "success": true,
    "state": { ... }
}
```

#### POST /api/actions/execute

Start plan execution.

#### POST /api/actions/continue

Continue after answering questions.

#### POST /api/actions/cancel

Cancel current operation.

**Behavior:**
1. Terminate Claude subprocess
2. Update state to previous stable state (configured or planned)
3. Log cancellation in STATUS.md

#### POST /api/actions/reset

Archive and reset project.

#### POST /api/actions/retry

Retry after error (return to previous state).

#### GET /api/config

Get project configuration.

#### POST /api/config

Save project configuration.

**Request:**
```json
{
    "projectName": "My Project",
    "projectDescription": "Build a web scraper",
    "defaultModel": "sonnet",
    "askQuestions": true
}
```

#### GET /api/questions

Get pending questions.

**Response:**
```json
{
    "hasQuestions": true,
    "questions": [
        {
            "number": 1,
            "topic": "Database Choice",
            "question": "Which database should we use?",
            "answer": ""
        }
    ]
}
```

#### POST /api/questions/answer

Submit question answers.

**Request:**
```json
{
    "answers": {
        "1": "PostgreSQL",
        "2": "Yes, use Docker"
    }
}
```

#### POST /api/questions/skip

Skip questions (let Claude decide).

#### GET /api/system/status

Get system status.

**Response:**
```json
{
    "installed": true,
    "version": "2.1.19",
    "email": "user@example.com"
}
```

#### POST /api/system/open-output

Open output folder in file explorer.

---

## File Structure

```
c:\NEOGOV\AIPM\
├── server/
│   ├── __init__.py
│   ├── app.py                      # Flask app, routes, SSE
│   ├── state_manager.py            # State machine, STATUS.md parsing
│   ├── process_manager.py          # Claude subprocess management
│   ├── config_manager.py           # Configuration handling
│   ├── templates/
│   │   └── conductor.html          # HTML with Alpine.js
│   └── static/
│       ├── css/
│       │   └── conductor.css       # Styles
│       └── js/
│           ├── api.js              # API client + SSE
│           └── app.js              # Alpine.js application
├── STATUS.md                        # State + human-readable status
├── Questions_For_You.md            # Claude's questions
├── config/
│   └── project-config.json         # User configuration
├── docs/
│   ├── planning/                   # Claude's work files
│   └── REBUILD_ARCHITECTURE.md     # This document
├── output/                          # Generated files
└── requirements.txt                 # Python dependencies
```

### requirements.txt

```
flask>=2.3.0
pyyaml>=6.0
portalocker>=2.7.0
```

**Note:** `portalocker` provides cross-platform file locking (Windows + Unix).

---

## Implementation Plan

### Phase 1: Backend Foundation (8-10 hours)

**Goal:** Reliable state and process management

**Tasks:**

1. **StateManager class** (3-4 hours)
   - Parse STATUS.md with YAML frontmatter
   - Implement state machine transitions
   - Write frontmatter updates atomically
   - Handle missing/malformed files gracefully

2. **ProcessManager class** (3-4 hours)
   - Direct subprocess management (no cmd indirection)
   - PID tracking that actually works
   - Output capture for logging
   - Stop/cancel functionality
   - Timeout detection

3. **Cross-platform file locking** (1-2 hours)
   - Install and configure portalocker
   - Atomic file updates
   - Handle lock contention

**Success Criteria:**
- [ ] Can parse STATUS.md frontmatter correctly
- [ ] State transitions work per state machine
- [ ] Can start Claude and track its PID
- [ ] Can detect when Claude exits (success or crash)
- [ ] Can stop Claude gracefully
- [ ] File operations work on Windows
- [ ] Unit tests pass

**Testing:**
```python
def test_state_transition():
    manager = StateManager()
    manager.set_state('configured')
    manager.transition('generate_plan')
    assert manager.get_state()['state'] == 'planning'

def test_process_tracking():
    pm = ProcessManager()
    pid = pm.start_claude('echo test', '.')
    assert pm.is_running()
    pm.stop()
    assert not pm.is_running()
```

---

### Phase 2: API Layer (4-6 hours)

**Goal:** Flask routes and SSE endpoint

**Tasks:**

1. **Refactor app.py** (2-3 hours)
   - Use StateManager for all state operations
   - Use ProcessManager for all subprocess operations
   - Clean up duplicated logic
   - Proper error handling

2. **Add SSE endpoint** (1-2 hours)
   - /api/events with state streaming
   - Proper headers for SSE
   - Handle client disconnection

3. **Add new action endpoints** (1 hour)
   - /api/actions/cancel
   - /api/actions/retry
   - Update existing endpoints to use managers

**Success Criteria:**
- [ ] All endpoints return proper JSON
- [ ] SSE streams state updates
- [ ] Cancel actually stops Claude
- [ ] Retry recovers from error state
- [ ] No business logic in routes

**Testing:**
```bash
# Test SSE
curl -N http://localhost:8080/api/events

# Test cancel
curl -X POST http://localhost:8080/api/actions/cancel
```

---

### Phase 3: Frontend Rebuild (8-12 hours)

**Goal:** Clean, reactive UI with Alpine.js

**Tasks:**

1. **HTML structure** (2-3 hours)
   - Create conductor.html with Alpine.js directives
   - Semantic HTML structure
   - Accessibility attributes

2. **CSS from scratch** (3-4 hours)
   - Design tokens
   - Component styles
   - Responsive design
   - No framework dependencies

3. **JavaScript** (3-5 hours)
   - api.js: Fetch wrapper + SSE client
   - app.js: Alpine.js components
   - All state derived from server
   - Reactive updates via SSE

**Success Criteria:**
- [ ] No inline styles or scripts
- [ ] All states render correctly
- [ ] SSE updates UI in real-time
- [ ] Questions flow works
- [ ] Mobile responsive
- [ ] No console errors
- [ ] Works in Chrome, Firefox, Edge

**Testing:**
- Manual testing of all user flows
- Test with slow network (Chrome DevTools)
- Test SSE reconnection (disconnect/reconnect)
- Mobile viewport testing

---

### Phase 4: Integration Testing (4-6 hours)

**Goal:** End-to-end verification

**Tasks:**

1. **Happy path testing** (2 hours)
   - Fresh start → configure → plan → execute → complete
   - Questions flow
   - Reset and start new project

2. **Error path testing** (2 hours)
   - Claude crashes mid-execution
   - User cancels during planning
   - Network disconnection during SSE
   - Malformed STATUS.md

3. **Edge case testing** (2 hours)
   - Two browser tabs (detect and warn)
   - Browser refresh during execution
   - Very long-running operations

**Success Criteria:**
- [ ] Complete workflow works
- [ ] Errors display helpful messages
- [ ] Recovery works from all error states
- [ ] No orphan processes
- [ ] State is consistent after any operation

---

### Phase 5: Migration and Cleanup (2-4 hours)

**Goal:** Safe transition from old code

**Tasks:**

1. **Backup** (0.5 hours)
   - Archive old conductor.html
   - Archive old app.py

2. **Migration** (1-2 hours)
   - Deploy new code
   - Test with existing STATUS.md files
   - Verify config migration

3. **Documentation** (1 hour)
   - Update README
   - Document new architecture
   - Note breaking changes

4. **Cleanup** (0.5 hours)
   - Remove dead code
   - Remove unused dependencies

**Success Criteria:**
- [ ] Old code archived
- [ ] New code deployed
- [ ] Existing projects still work
- [ ] Documentation updated

---

## Risk Mitigation

### Risk 1: Windows Subprocess Issues

**Mitigation:**
- Test on Windows first, not last
- Use `CREATE_NEW_CONSOLE` flag
- Don't rely on shell=True
- Test PID tracking explicitly

### Risk 2: SSE Reliability

**Mitigation:**
- EventSource auto-reconnects
- Fall back to polling if SSE fails
- Show connection status to user
- Test with network interruption

### Risk 3: State Corruption

**Mitigation:**
- Atomic file writes with portalocker
- Validate frontmatter on read
- Fall back to safe defaults
- Log all state transitions

### Risk 4: Feature Regression

**Mitigation:**
- Create feature checklist from old code
- Test each feature before marking complete
- Keep old code archived for reference
- Run both versions in parallel during testing

### Risk 5: Timeline Overrun

**Mitigation:**
- Realistic estimates (28-40 hours)
- Build incrementally (backend → API → frontend)
- Each phase is independently testable
- Can ship partial improvements

---

## Timeline Summary

| Phase | Estimated Hours | Cumulative |
|-------|-----------------|------------|
| 1. Backend Foundation | 8-10 | 8-10 |
| 2. API Layer | 4-6 | 12-16 |
| 3. Frontend Rebuild | 8-12 | 20-28 |
| 4. Integration Testing | 4-6 | 24-34 |
| 5. Migration & Cleanup | 2-4 | 26-38 |
| **Buffer for unknowns** | 4-6 | **30-44** |

**Realistic total: 30-44 hours**

---

## Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| File locking | portalocker | Cross-platform, well-maintained |
| State storage | STATUS.md frontmatter | Single source of truth |
| Real-time updates | SSE | Simpler than WebSockets, native reconnect |
| Frontend framework | Alpine.js | Reactive without build complexity |
| Layer count | 3 | YAGNI - separate service layer unnecessary |
| Subprocess | Direct (no cmd start) | PID tracking actually works |

---

## Next Steps

1. **Review this document** - Get alignment on revised architecture
2. **Set up development environment** - Ensure portalocker installs on Windows
3. **Start Phase 1** - StateManager and ProcessManager classes
4. **Iterate** - Build, test, refine

**Approval checkpoint:** After Phase 1 completes, verify backend works before proceeding to frontend.
