# Findings and Research

## Domain Understanding

### What is the Job to Be Done?

Create comprehensive technical documentation for the Simple Claude Conductor Web UI system. The documentation must explain:

1. **System Architecture**: How the Flask backend, StateManager, ProcessManager, and Alpine.js frontend work together
2. **State Machine**: All states, transitions, and how state is persisted in STATUS.md with YAML frontmatter
3. **Process Management**: How Claude subprocess is started, tracked, and monitored on Windows
4. **API Reference**: Complete documentation of all 30+ REST endpoints with request/response formats
5. **Frontend Architecture**: Alpine.js reactive state, SSE connections, and UI design patterns
6. **Configuration**: project.yaml schema and project-config.json formats
7. **Deployment**: How to run and troubleshoot the server

The documentation will be created in `docs/SimpleClaudeConductorDocumentation/` with 8 separate files for different aspects of the system.

**Key constraint**: Must only document the current implementation in `server/` directory, NOT archived or old code.

### Domain Familiarity Assessment

**Level**: High

**Reasoning**:
- I have extensive knowledge of Flask web applications, REST APIs, and SSE (Server-Sent Events)
- I understand Python subprocess management, including Windows-specific considerations (CREATE_NEW_CONSOLE flags)
- I'm familiar with Alpine.js reactive framework patterns and SSE-driven real-time UIs
- I understand state machine design patterns and YAML frontmatter for file-based state persistence
- I know documentation best practices including API reference formats, architecture diagrams, and code examples

This is a technical documentation task for a web application stack I'm very familiar with. No research needed.

### Key Technical Concepts Identified

From reading the source files, I've identified the core technical patterns:

**State Machine**:
- 8 states: reset, configured, planning, planned, executing, questions, complete, error
- Transitions defined in TRANSITIONS dict in state_manager.py:24-59
- Single source of truth: STATUS.md with YAML frontmatter
- Thread-safe file operations with portalocker

**Process Management**:
- Direct subprocess.Popen (not cmd /c start) for proper PID tracking
- Windows CREATE_NEW_CONSOLE flag for separate console window
- Exit callbacks for completion detection
- TimeoutMonitor for stall detection

**Frontend Architecture**:
- Alpine.js for reactive state (conductorApp() function)
- SSE at /api/events for real-time updates (1 second polling)
- Stage-based progress UI (5 stages: Start, Configure, Plan, Execute, Complete)
- File upload with drag-and-drop

**API Design**:
- REST endpoints under /api/
- Action endpoints: /api/actions/{generate-plan, execute, continue, cancel, retry, reset}
- Resource endpoints: /api/config, /api/references, /api/questions, /api/plan
- SSE endpoint: /api/events for state streaming

### Assumptions Made

Since `interrupt_for_questions: false` in project.yaml:

1. **Documentation structure**: Using the 8-file structure specified in the prompt (README, ARCHITECTURE, STATE_MACHINE, PROCESS_MANAGEMENT, API_REFERENCE, FRONTEND, CONFIGURATION, DEPLOYMENT)

2. **Diagram format**: Will use Mermaid diagrams for state machine and architecture (readable in most Markdown viewers including GitHub)

3. **Code examples**: Will include curl examples for API endpoints and JavaScript snippets for frontend patterns

4. **Audience**: Documentation is for developers who will maintain this code (not end users), so technical language is appropriate

5. **Current state only**: Will only document the v2.0 Web UI in the `server/` directory, completely ignoring archive/ and old files

### Research Conducted

None needed. Domain familiarity is high.

### Remaining Uncertainties

None that would block documentation. All source files are available to read for accurate documentation.

### Files Read for Complete Documentation

**Backend (ALL READ)**:
- [x] server/app.py - 1123 lines, 33 endpoints cataloged below
- [x] server/state_manager.py - 461 lines, state machine with TRANSITIONS dict
- [x] server/process_manager.py - 353 lines, ProcessManager and TimeoutMonitor classes
- [x] server/static/js/api.js - 171 lines, APIClient class with SSE support
- [x] server/static/css/conductor.css - 636 lines, design tokens and components
- [x] server/static/js/app.js - 573 lines, conductorApp() Alpine.js application
- [x] server/templates/conductor.html (read earlier in session)

**Configuration files**:
- [x] project.yaml (already read)
- Config format: project-config.json stores { projectName, projectDescription, defaultModel }

## Complete API Endpoint Catalog

**Main Routes** (3):
- GET / - Serve conductor.html
- GET /health - Health check endpoint
- GET /api/events - SSE endpoint for real-time state updates (1 second interval)

**State API** (2):
- GET /api/state - Get current state from StateManager
- GET /api/status - Backward-compatible endpoint with raw STATUS.md content

**Action API** (6):
- POST /api/actions/generate-plan - Start Claude to generate plan
- POST /api/actions/execute - Start Claude to execute plan
- POST /api/actions/continue - Continue Claude after answering questions
- POST /api/actions/cancel - Cancel current operation
- POST /api/actions/retry - Retry after error state
- POST /api/actions/reset - Reset to initial state

**Configuration API** (3):
- GET /api/config - Read project-config.json
- POST /api/config - Save project-config.json
- POST /api/prompt/review - Analyze prompt quality (heuristic-based)

**Reference Files API** (4):
- GET /api/references - List files in File_References_For_Your_Project/
- GET /api/references/open - Open references folder in file explorer
- POST /api/references/upload - Handle file uploads to reference folder
- POST /api/references/archive - Archive reference files to timestamped folder

**Questions API** (3):
- GET /api/questions - Parse Questions_For_You.md and return as JSON
- POST /api/questions/answer - Write answers back to Questions_For_You.md
- POST /api/questions/skip - Mark questions as skipped

**Claude Control API** (3):
- GET /api/claude/check - Check if Claude is installed and logged in
- POST /api/claude/login - Open login window
- GET /api/plan/open - Open task-plan.md in default editor

**Legacy Endpoints** (3 - backward compatibility):
- POST /api/claude/generate-plan → calls action_generate_plan()
- POST /api/claude/execute-plan → calls action_execute_plan()
- POST /api/claude/continue → calls action_continue()

**Cost Report API** (2):
- GET /api/cost - Get cost report data from output/cost_report.md
- POST /api/cost/generate - Generate new cost report

**Archive API** (4):
- POST /api/archive - Archive current project to timestamped folder
- POST /api/reset - Archive + reset to fresh state
- GET /api/archive/list - List all archived projects
- GET /api/archive/open - Open archive folder in file explorer

**Output API** (2):
- GET /api/output/open - Open output folder in file explorer
- POST /api/system/open-output - Same as output/open

**System API** (1):
- GET /api/system/status - Same as /api/claude/check

**Server Management** (1):
- POST /api/shutdown - Graceful server shutdown

**Total: 38 endpoints**

## State Machine Complete Definition

**States** (8):
1. reset - Initial state, ready to start
2. configured - Project configured, ready to generate plan
3. planning - Claude is generating plan
4. planned - Plan generated, ready to execute
5. executing - Claude is executing plan
6. questions - Claude has questions that need answers
7. complete - Project complete
8. error - Error occurred

**Transitions** (from state_manager.py:24-59):
```
reset → configure → configured
configured → generate_plan → planning
configured → reset → reset
planning → plan_complete → planned
planning → cancel → configured
planning → error → error
planned → execute → executing
planned → reset → reset
executing → questions_detected → questions
executing → phase_complete → executing
executing → all_complete → complete
executing → cancel → planned
executing → error → error
questions → answer → executing
questions → skip → executing
questions → cancel → planned
complete → reset → reset
error → retry → [previous_state]
error → reset → reset
```

## Frontend Architecture

**Alpine.js State Structure**:
- connection state: connected, loading, lastUpdateTime, secondsSinceUpdate
- server state: state, phase, total_phases, phase_name, process_id, error, activity
- configuration: projectName, projectDescription, defaultModel
- reference files: referenceFiles[], noReferenceFiles, isDragging
- questions: questions[]
- system status: installed, email, version
- stages for progress UI: [Start, Configure, Plan, Execute, Complete]

**Computed Properties** (11):
- statusDotClass - CSS class based on state
- statusTitle - Human-readable status
- actionButtonText - Dynamic button label
- canPerformAction - Disable during auto-transitions
- canCancel - Show cancel button
- showConfig - Show config panel
- showHeartbeat - Show heartbeat during active states
- heartbeatText - Connection status message
- progressPercent - Phase completion percentage
- phaseLabel - "Phase X of Y: Name"
- isStageComplete / isStageActive - For progress indicator

**SSE Pattern**:
- EventSource connects to /api/events
- Receives state updates every 1 second
- Auto-reconnect up to 10 attempts
- onStateUpdate callback merges server state with local state
- onConnectionChange updates UI connection indicator

## CSS Design Tokens

**Colors**:
- Primary: #ff6b35 (orange)
- Success: #22c55e (green)
- Warning: #f59e0b (yellow)
- Error: #ef4444 (red)
- Neutral: #6b7280 (gray)

**Dark Theme**:
- Body BG: #111827
- Card BG: #1f2937
- Input BG: #374151
- Text: #f9fafb (primary), #9ca3af (secondary), #6b7280 (muted)

**Components**:
- Cards with collapsible headers
- Stage progress indicator with connector lines
- Status dots with pulse animation
- Progress bars
- Buttons (primary, secondary, small, danger)
- Forms with focus states
- Questions with textarea inputs
- Dropzone for file upload
- File list with max-height scrolling

## Process Management Key Details

**Windows Subprocess Pattern**:
```python
subprocess.Popen(['claude', '-p', prompt],
    cwd=working_dir,
    creationflags=subprocess.CREATE_NEW_CONSOLE  # Windows only
)
```

**Why CREATE_NEW_CONSOLE?**
- Claude gets its own console window
- User can see Claude output directly
- PID can still be tracked properly
- No cmd /c start indirection (which breaks PID tracking)

**Exit Callbacks**:
- _monitor_exit() thread waits for process.wait()
- on_exit callback called with return code
- Used to detect plan generation success and execution completion

**Timeout Monitoring**:
- STALL_THRESHOLD = 5 minutes (no STATUS.md update)
- HARD_TIMEOUT = 30 minutes (total runtime)
- Monitors STATUS.md file modification time
- Reports stalled/timed_out flags in /api/events

## Next Steps

1. ✅ Complete domain understanding assessment
2. ✅ Read all source files in full
3. ✅ Catalog all API endpoints
4. ✅ Document state machine transitions
5. ✅ Document frontend architecture
6. Generate 8 documentation files with accurate technical details
