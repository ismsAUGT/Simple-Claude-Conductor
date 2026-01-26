# API Reference

Complete reference for all 38 REST API endpoints in the Simple Claude Conductor Web UI v2.0.

## Base URL

```
http://localhost:8080
```

All API endpoints are prefixed with `/api` except for root routes.

## Response Format

All API responses return JSON except for SSE endpoint:

**Success Response**:
```json
{
  "success": true,
  "message": "Optional message",
  ...additional fields...
}
```

**Error Response**:
```json
{
  "success": false,
  "error": "Error message",
  "type": "ErrorClassName"
}
```

## Endpoint Categories

- [Main Routes](#main-routes) - Root and health check
- [Server-Sent Events](#server-sent-events) - Real-time updates
- [State API](#state-api) - Get application state
- [Action API](#action-api) - Trigger state transitions
- [Configuration API](#configuration-api) - Manage project config
- [Reference Files API](#reference-files-api) - Manage reference files
- [Questions API](#questions-api) - Handle Claude questions
- [Claude Control API](#claude-control-api) - Claude CLI operations
- [Cost Report API](#cost-report-api) - Cost tracking
- [Archive API](#archive-api) - Project archival
- [Output API](#output-api) - Access output folder
- [System API](#system-api) - System operations
- [Server Management](#server-management) - Server control

---

## Main Routes

### GET /

**Description**: Serve the main conductor UI

**Response**: HTML page (conductor.html)

**Example**:
```bash
curl http://localhost:8080/
```

---

### GET /health

**Description**: Health check endpoint for monitoring

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2026-01-26T10:00:00.000000"
}
```

**Example**:
```bash
curl http://localhost:8080/health
```

---

## Server-Sent Events

### GET /api/events

**Description**: Server-Sent Events stream for real-time state updates

**Protocol**: SSE (Server-Sent Events)

**Update Interval**: 1 second

**Response Format**: SSE stream with JSON data

**Event Data**:
```json
{
  "state": "executing",
  "phase": 2,
  "total_phases": 5,
  "phase_name": "Implementation",
  "process_id": 1234,
  "process_start": "2026-01-26T10:00:00",
  "last_updated": "2026-01-26T10:05:00",
  "error": null,
  "previous_state": null,
  "activity": "Executing phase 2...",
  "claudeRunning": true,
  "processPid": 1234,
  "stalled": false,
  "timedOut": false
}
```

**JavaScript Example**:
```javascript
const eventSource = new EventSource('/api/events');

eventSource.onmessage = (event) => {
  const state = JSON.parse(event.data);
  console.log('State update:', state);
};

eventSource.onerror = (error) => {
  console.error('SSE error:', error);
};
```

**Headers**:
- `Cache-Control: no-cache`
- `Connection: keep-alive`
- `X-Accel-Buffering: no` (disable nginx buffering)

---

## State API

### GET /api/state

**Description**: Get current application state from StateManager

**Response**:
```json
{
  "state": "planned",
  "phase": 1,
  "total_phases": 3,
  "phase_name": "Setup",
  "process_id": null,
  "process_start": null,
  "last_updated": "2026-01-26T10:00:00",
  "error": null,
  "previous_state": null,
  "activity": "Plan generated with 3 phase(s). Ready to execute!",
  "claudeRunning": false,
  "processPid": null,
  "stalled": false,
  "timedOut": false
}
```

**Example**:
```bash
curl http://localhost:8080/api/state
```

---

### GET /api/status

**Description**: Backward-compatible status endpoint with raw STATUS.md content

**Response**:
```json
{
  "state": "planned",
  "phase": 1,
  "total": 3,
  "phaseName": "Setup",
  "lastUpdated": "2026-01-26T10:00:00",
  "planGenerated": true,
  "claudeRunning": false,
  "raw": "---\nstate: planned\n...\n---\n# Project Status\n..."
}
```

**Example**:
```bash
curl http://localhost:8080/api/status
```

**Note**: Includes `raw` field with full STATUS.md content for debugging.

---

## Action API

### POST /api/actions/generate-plan

**Description**: Start Claude to generate a plan

**Request Body**: None (or empty JSON object)

**Response**:
```json
{
  "success": true,
  "message": "Plan generation started",
  "pid": 1234
}
```

**Errors**:
- `400`: Claude is already running
- `500`: Failed to start Claude (e.g., not in PATH)

**State Transition**: configured → planning → planned (on success)

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/generate-plan
```

---

### POST /api/actions/execute

**Description**: Start Claude to execute the plan

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Plan execution started",
  "pid": 1235
}
```

**Errors**:
- `400`: Claude is already running
- `500`: Failed to start Claude

**State Transition**: planned → executing → complete (on success)

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/execute
```

---

### POST /api/actions/continue

**Description**: Continue Claude after answering questions

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Continuing execution",
  "pid": 1236
}
```

**Errors**:
- `400`: Claude is already running
- `500`: Failed to start Claude

**State Transition**: questions → executing

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/continue
```

---

### POST /api/actions/cancel

**Description**: Cancel current operation

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "wasRunning": true,
  "stoppedCleanly": true,
  "message": "Operation cancelled"
}
```

**Fields**:
- `wasRunning`: Whether process was running when cancel was called
- `stoppedCleanly`: True if terminated gracefully, false if force killed

**State Transition**:
- planning → configured
- executing → planned
- questions → planned

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/cancel
```

---

### POST /api/actions/retry

**Description**: Retry after error state

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "previousState": "planning",
  "message": "Returned to planning state"
}
```

**Errors**:
- `400`: Can only retry from error state

**State Transition**: error → previous_state

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/retry
```

---

### POST /api/actions/reset

**Description**: Reset to initial state

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "State reset to initial"
}
```

**Side Effects**:
- Stops any running process
- Resets state to 'reset'
- Clears phase, error, activity

**State Transition**: any → reset

**Example**:
```bash
curl -X POST http://localhost:8080/api/actions/reset
```

---

## Configuration API

### GET /api/config

**Description**: Read current project configuration

**Response**:
```json
{
  "projectName": "My Project",
  "projectDescription": "Build a tool that...",
  "defaultModel": "sonnet"
}
```

**File**: Reads from `config/project-config.json`

**Example**:
```bash
curl http://localhost:8080/api/config
```

---

### POST /api/config

**Description**: Save project configuration

**Request Body**:
```json
{
  "projectName": "My Project",
  "projectDescription": "Build a tool that does X, Y, and Z",
  "defaultModel": "sonnet"
}
```

**Response**:
```json
{
  "success": true
}
```

**Side Effects**:
- Writes to `config/project-config.json`
- If in reset state, transitions to configured

**Example**:
```bash
curl -X POST http://localhost:8080/api/config \
  -H "Content-Type: application/json" \
  -d '{
    "projectName": "My Project",
    "projectDescription": "A tool for...",
    "defaultModel": "sonnet"
  }'
```

---

### POST /api/prompt/review

**Description**: Analyze prompt quality and provide feedback

**Request Body**:
```json
{
  "description": "Build me a thing"
}
```

**Response**:
```json
{
  "success": true,
  "quality": "needs_work",
  "feedback": [
    "Too short: Try adding more detail about what you want to build",
    "Be more specific: Mention specific features, functions, or requirements",
    "Consider specifying what the expected output should look like"
  ]
}
```

**Quality Levels**:
- `good`: Prompt has sufficient detail
- `needs_work`: Prompt is too vague or short

**Heuristics**:
- Word count (< 10 words = too short, < 30 = could be better)
- Specificity words (should, must, need, feature, etc.)
- Output format hints (file, generate, create, etc.)
- Technology mentions (python, react, api, etc.)

**Example**:
```bash
curl -X POST http://localhost:8080/api/prompt/review \
  -H "Content-Type: application/json" \
  -d '{"description": "Build me a dashboard"}'
```

---

## Reference Files API

### GET /api/references

**Description**: List files in reference folder

**Response**:
```json
[
  {
    "name": "sample_data.csv",
    "size": 1024,
    "isDir": false
  },
  {
    "name": "screenshot.png",
    "size": 204800,
    "isDir": false
  }
]
```

**Folder**: `File_References_For_Your_Project/`

**Example**:
```bash
curl http://localhost:8080/api/references
```

---

### GET /api/references/open

**Description**: Open reference folder in file explorer

**Response**:
```json
{
  "success": true
}
```

**Behavior**:
- Windows: `os.startfile()`
- macOS: `open` command
- Linux: `xdg-open` command

**Example**:
```bash
curl http://localhost:8080/api/references/open
```

---

### POST /api/references/upload

**Description**: Upload files to reference folder

**Request**: multipart/form-data with file(s)

**Response**:
```json
{
  "success": true,
  "files": ["sample_data.csv", "screenshot.png"]
}
```

**Errors**:
- `400`: No files provided

**JavaScript Example**:
```javascript
const formData = new FormData();
formData.append('files', file1);
formData.append('files', file2);

await fetch('/api/references/upload', {
  method: 'POST',
  body: formData
});
```

**Curl Example**:
```bash
curl -X POST http://localhost:8080/api/references/upload \
  -F "files=@sample_data.csv" \
  -F "files=@screenshot.png"
```

---

### POST /api/references/archive

**Description**: Archive all reference files to timestamped folder

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "archived": ["sample_data.csv", "screenshot.png"],
  "archivePath": "/path/to/archive/2026-01-26_1000_reference_files"
}
```

**Errors**:
- `400`: Reference folder does not exist
- `400`: No files to archive

**Side Effects**: Moves all files from `File_References_For_Your_Project/` to `archive/[timestamp]_reference_files/`

**Example**:
```bash
curl -X POST http://localhost:8080/api/references/archive
```

---

## Questions API

### GET /api/questions

**Description**: Parse Questions_For_You.md and return questions as JSON

**Response**:
```json
{
  "hasQuestions": true,
  "questions": [
    {
      "number": 1,
      "topic": "Authentication Method",
      "question": "Should we use JWT or session-based auth?",
      "answer": ""
    },
    {
      "number": 2,
      "topic": "Database",
      "question": "Which database should we use?",
      "answer": "PostgreSQL"
    }
  ],
  "count": 2
}
```

**Side Effects**: If unanswered questions detected while in executing state, transitions to questions state

**Example**:
```bash
curl http://localhost:8080/api/questions
```

---

### POST /api/questions/answer

**Description**: Write answers back to Questions_For_You.md

**Request Body**:
```json
{
  "answers": {
    "1": "Use JWT tokens",
    "2": "PostgreSQL"
  }
}
```

**Response**:
```json
{
  "success": true
}
```

**Errors**:
- `400`: Questions file not found

**Side Effects**: Updates Questions_For_You.md with user's answers

**Example**:
```bash
curl -X POST http://localhost:8080/api/questions/answer \
  -H "Content-Type: application/json" \
  -d '{
    "answers": {
      "1": "Use JWT tokens",
      "2": "PostgreSQL"
    }
  }'
```

---

### POST /api/questions/skip

**Description**: Mark all questions as skipped (let Claude decide)

**Request Body**: None

**Response**:
```json
{
  "success": true
}
```

**Side Effects**: Replaces all answer placeholders with "(Skipped - Claude will decide)"

**Example**:
```bash
curl -X POST http://localhost:8080/api/questions/skip
```

---

## Claude Control API

### GET /api/claude/check

**Description**: Check if Claude is installed and logged in

**Response**:
```json
{
  "installed": true,
  "version": "0.5.0",
  "loggedIn": true,
  "email": "Logged in"
}
```

**Implementation**:
- Checks if `claude` is in PATH using `shutil.which()`
- Runs `claude --version` to verify functionality
- If version command works, assumes logged in

**Example**:
```bash
curl http://localhost:8080/api/claude/check
```

---

### POST /api/claude/login

**Description**: Open Claude login in new terminal window

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Login window opened"
}
```

**Behavior**:
- Windows: Opens new cmd window with `claude login`
- macOS/Linux: Runs `claude login` in terminal

**Example**:
```bash
curl -X POST http://localhost:8080/api/claude/login
```

---

### GET /api/plan/open

**Description**: Open task-plan.md in default editor

**Response**:
```json
{
  "success": true
}
```

**Errors**:
- `400`: Plan file not found

**Behavior**: Opens `docs/planning/task-plan.md` using platform default

**Example**:
```bash
curl http://localhost:8080/api/plan/open
```

---

### Legacy Endpoints (Backward Compatibility)

#### POST /api/claude/generate-plan
Alias for `/api/actions/generate-plan`

#### POST /api/claude/execute-plan
Alias for `/api/actions/execute`

#### POST /api/claude/continue
Alias for `/api/actions/continue`

---

## Cost Report API

### GET /api/cost

**Description**: Get cost report data if available

**Response** (when report exists):
```json
{
  "available": true,
  "metrics": {
    "totalCost": 1.23,
    "cacheEfficiency": 85.5,
    "subagentCount": 2,
    "delegationRatio": 15.5,
    "model": "claude-sonnet-4-5"
  },
  "rawContent": "# Cost Report\n\n..."
}
```

**Response** (when report doesn't exist):
```json
{
  "available": false,
  "message": "No cost report generated yet"
}
```

**File**: Reads from `output/cost_report.md`

**Example**:
```bash
curl http://localhost:8080/api/cost
```

---

### POST /api/cost/generate

**Description**: Generate a new cost report

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Cost report generated"
}
```

**Errors**:
- `400`: Cost report script not found
- `500`: Failed to generate report

**Implementation**: Runs `python scripts/generate_cost_report.py <project_root>`

**Example**:
```bash
curl -X POST http://localhost:8080/api/cost/generate
```

---

## Archive API

### POST /api/archive

**Description**: Archive current project to timestamped folder

**Request Body**:
```json
{
  "projectName": "My Project"
}
```

**Response**:
```json
{
  "success": true,
  "archivePath": "/path/to/archive/2026-01-26_1000_My_Project",
  "archived": [
    "docs/planning",
    "output",
    "STATUS.md",
    "Questions_For_You.md",
    "config/project-config.json"
  ]
}
```

**Side Effects**: Copies listed items to archive folder (does NOT delete originals)

**Example**:
```bash
curl -X POST http://localhost:8080/api/archive \
  -H "Content-Type: application/json" \
  -d '{"projectName": "My Project"}'
```

---

### POST /api/reset

**Description**: Archive current project and reset to fresh state

**Request Body**:
```json
{
  "projectName": "My Project"
}
```

**Response**:
```json
{
  "success": true,
  "archived": true,
  "archivePath": "/path/to/archive/2026-01-26_1000_My_Project",
  "message": "Project reset. Old files archived."
}
```

**Side Effects**:
- Archives project (if content exists)
- Deletes working files:
  - docs/planning/*.md
  - STATUS.md
  - Questions_For_You.md
  - config/project-config.json
- Clears output folder (except .gitkeep)
- Creates fresh Questions_For_You.md
- Resets state to 'reset'

**Example**:
```bash
curl -X POST http://localhost:8080/api/reset \
  -H "Content-Type: application/json" \
  -d '{"projectName": "My Project"}'
```

---

### GET /api/archive/list

**Description**: List all archived projects

**Response**:
```json
[
  {
    "name": "2026-01-26_1000_My_Project",
    "date": "2026-01-26",
    "time": "1000",
    "project": "My_Project"
  },
  {
    "name": "2026-01-25_1430_Other_Project",
    "date": "2026-01-25",
    "time": "1430",
    "project": "Other_Project"
  }
]
```

**Sort Order**: Most recent first

**Example**:
```bash
curl http://localhost:8080/api/archive/list
```

---

### GET /api/archive/open

**Description**: Open archive folder in file explorer

**Response**:
```json
{
  "success": true
}
```

**Behavior**: Opens `archive/` folder using platform file manager

**Example**:
```bash
curl http://localhost:8080/api/archive/open
```

---

## Output API

### GET /api/output/open

**Description**: Open output folder in file explorer

**Response**:
```json
{
  "success": true
}
```

**Behavior**: Opens `output/` folder using platform file manager

**Example**:
```bash
curl http://localhost:8080/api/output/open
```

---

### POST /api/system/open-output

**Description**: Alias for `/api/output/open`

**Example**:
```bash
curl -X POST http://localhost:8080/api/system/open-output
```

---

## System API

### GET /api/system/status

**Description**: Alias for `/api/claude/check`

**Response**: Same as `/api/claude/check`

**Example**:
```bash
curl http://localhost:8080/api/system/status
```

---

## Server Management

### POST /api/shutdown

**Description**: Graceful server shutdown

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Server shutting down..."
}
```

**Side Effects**:
- Stops any running Claude process
- Terminates Flask server

**Example**:
```bash
curl -X POST http://localhost:8080/api/shutdown
```

---

## Error Handling

### Global Exception Handler

All unhandled exceptions return:

```json
{
  "success": false,
  "error": "Error message",
  "type": "ExceptionClassName"
}
```

**Status Code**: 500

### 404 Handler

```json
{
  "success": false,
  "error": "Endpoint not found"
}
```

**Status Code**: 404

---

## Common Response Patterns

### Success with Data

```json
{
  "success": true,
  "data": {...}
}
```

### Success with Message

```json
{
  "success": true,
  "message": "Operation completed"
}
```

### Validation Error

```json
{
  "success": false,
  "error": "Validation error message"
}
```

**Status Code**: 400

### Server Error

```json
{
  "success": false,
  "error": "Internal server error"
}
```

**Status Code**: 500

---

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - API layer design
- [STATE_MACHINE.md](STATE_MACHINE.md) - State transitions triggered by actions
- [PROCESS_MANAGEMENT.md](PROCESS_MANAGEMENT.md) - Process control integration
- [FRONTEND.md](FRONTEND.md) - API client implementation
