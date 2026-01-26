# Deployment Guide

This document describes how to install, run, and troubleshoot the Simple Claude Conductor Web UI.

## Prerequisites

### Required

1. **Python 3.8 or higher**
   ```bash
   python --version  # Should be 3.8+
   ```

2. **Claude CLI installed and authenticated**
   ```bash
   # Install Claude CLI (if not already installed)
   # Visit https://claude.ai/cli for installation instructions

   # Login to Claude
   claude login

   # Verify installation
   claude --version
   ```

3. **Modern web browser**
   - Chrome 90+
   - Firefox 88+
   - Safari 14+
   - Edge 90+

### Optional

- **portalocker** (for file locking)
  ```bash
  pip install portalocker
  ```
  If not installed, system will work without file locking (fine for single-user local use).

---

## Installation

### 1. Get the Code

```bash
# If using git
git clone <repository-url>
cd AIPM

# Or if you have the files already
cd /path/to/AIPM
```

---

### 2. Install Python Dependencies

```bash
# The Flask server has minimal dependencies (Flask only)
pip install flask

# Optional: Install portalocker for file locking
pip install portalocker
```

**Dependencies**:
- **flask** (required) - Web framework
- **portalocker** (optional) - File locking for concurrent access
- **pyyaml** (likely already installed) - YAML parsing

---

### 3. Verify Claude CLI

```bash
# Check if Claude is in PATH
which claude  # macOS/Linux
where claude  # Windows

# Check version
claude --version

# Verify logged in (this should NOT prompt for login)
claude --version  # If this works, you're logged in
```

**If not installed**: Visit https://claude.ai/cli for installation instructions

**If not logged in**:
```bash
claude login
```

---

## Running the Server

### Basic Usage

```bash
# Navigate to project root
cd /path/to/AIPM

# Start the server
python server/app.py
```

**Expected Output**:
```
==================================================
  Simple Claude Conductor v2.0
==================================================

  Server running at: http://localhost:8080
  Project root: /path/to/AIPM

  Features:
    - SSE endpoint: /api/events
    - State machine with proper transitions
    - Process management with PID tracking

  Press Ctrl+C to stop the server.
==================================================
```

---

### Access the UI

Open your browser and navigate to:
```
http://localhost:8080
```

---

### Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.

**Graceful Shutdown**:
- Server stops any running Claude process (with 5 second timeout)
- Server shuts down cleanly

---

## First-Time Setup

### 1. Open the Web UI

Navigate to http://localhost:8080

---

### 2. Configure Your First Project

**Project Configuration Card**:
- Enter **Project Name** (e.g., "Task Dashboard")
- Enter **Project Description** (detailed description of what to build)
- Select **Model** (haiku | sonnet | opus)
- Upload **Reference Files** (optional - examples, templates, data)
  - Or check "I have no reference files to upload"

**Example Configuration**:
```
Project Name: Task Management Dashboard

Project Description:
Build a web-based task management dashboard with:
- User authentication (JWT)
- Drag-and-drop task boards
- Task filtering and search
- Due date reminders
- SQLite database
- Python/Flask backend
- React frontend

Model: sonnet
```

---

### 3. Generate Plan

Click **"Generate Plan"** button.

**What Happens**:
1. A new terminal window opens (Claude's console)
2. Claude generates a multi-phase plan
3. Plan is saved to `docs/planning/task-plan.md`
4. UI updates to "Plan Ready" state

**Duration**: 2-5 minutes depending on complexity

---

### 4. Review Plan

Click **"Open Plan"** to view `task-plan.md` in your default editor.

**Plan Contains**:
- Phase breakdown
- Success criteria for each phase
- Estimated outputs
- Risk assessment

---

### 5. Execute Plan

Click **"Execute Plan"** button.

**What Happens**:
1. Claude starts executing phases sequentially
2. UI shows real-time progress (phase N of M)
3. Files are generated in `output/` folder
4. STATUS.md updates with progress

**Duration**: Varies by project complexity (10 minutes to several hours)

---

### 6. Answer Questions (If Any)

If Claude has questions:
1. UI transitions to "Questions Pending" state
2. Answer questions in the web form
3. Click **"Submit Answers"** to continue

**Or**: Click **"Skip Questions"** to let Claude decide

---

### 7. View Results

When complete:
1. UI shows "Project Complete!" message
2. Click **"Open Output"** to view generated files
3. Review deliverables in `output/` folder

---

### 8. Start New Project

Click **"Start New Project"** to:
1. Archive current project
2. Reset to clean state
3. Begin configuration for new project

---

## Directory Structure

```
AIPM/
├── server/
│   ├── app.py                      # Flask application (START HERE)
│   ├── state_manager.py            # State management
│   ├── process_manager.py          # Process control
│   ├── templates/
│   │   └── conductor.html          # Main UI
│   └── static/
│       ├── js/
│       │   ├── app.js              # Alpine.js app
│       │   └── api.js              # API client
│       └── css/
│           └── conductor.css       # Styles
├── docs/
│   ├── SimpleClaudeConductorDocumentation/  # This documentation
│   └── planning/                   # Planning files (generated)
├── config/
│   └── project-config.json         # User config (created by UI)
├── File_References_For_Your_Project/  # Reference materials
├── output/                         # Generated deliverables
├── archive/                        # Archived projects
├── STATUS.md                       # Current state
├── Questions_For_You.md            # Questions from Claude
└── project.yaml                    # System configuration
```

---

## Configuration

### System Configuration

Edit `project.yaml` to customize behavior:
```yaml
execution:
  default_model: sonnet
  interrupt_for_questions: false
  delegation_mode: conservative

validation:
  enabled: true
  confidence_threshold: 0.8

limits:
  max_files_per_phase: 20
  max_total_files: 100
```

See [CONFIGURATION.md](CONFIGURATION.md) for full schema.

---

## Troubleshooting

### Problem: Server Won't Start

#### Error: "Port 8080 already in use"

**Cause**: Another process is using port 8080

**Solution 1 - Kill process using port**:
```bash
# Find process
lsof -ti:8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

**Solution 2 - Use different port**:

Edit `server/app.py`:
```python
app.run(host='127.0.0.1', port=8081, debug=False)
```

Then access at http://localhost:8081

---

#### Error: "ModuleNotFoundError: No module named 'flask'"

**Cause**: Flask not installed

**Solution**:
```bash
pip install flask
```

---

#### Error: "No module named 'server.state_manager'"

**Cause**: Not running from project root

**Solution**:
```bash
cd /path/to/AIPM  # Must be in project root
python server/app.py
```

---

### Problem: Claude Not Found

#### Error: "Claude CLI not found"

**Cause**: Claude not installed or not in PATH

**Solution**:
```bash
# Check if installed
which claude  # macOS/Linux
where claude  # Windows

# If not found, install Claude CLI
# Visit https://claude.ai/cli
```

---

#### Error: "Claude requires login"

**Cause**: Not authenticated

**Solution**:
```bash
claude login
```

Follow the prompts to authenticate.

---

### Problem: Plan Generation Hangs

#### Symptom: "Generating plan..." for >10 minutes

**Possible Causes**:
1. Very complex prompt
2. Claude is waiting for user input
3. Process crashed

**Diagnosis**:
```bash
# Check if Claude process is running
ps aux | grep claude  # macOS/Linux
tasklist | findstr claude  # Windows
```

**Solution 1 - Check Claude window**:
- Look for the Claude terminal window
- See if it's waiting for input or showing errors

**Solution 2 - Cancel and retry**:
- Click **"Cancel"** in UI
- Simplify project description
- Try again

**Solution 3 - Check STATUS.md**:
```bash
# View last update time
ls -l STATUS.md  # macOS/Linux
dir STATUS.md  # Windows

# If not updated in 5+ minutes, likely stalled
```

---

### Problem: Execution Fails

#### Error: "Claude exited with code 1"

**Possible Causes**:
1. Syntax error in generated code
2. Missing dependencies
3. Invalid configuration

**Solution**:
1. Check Claude terminal window for error details
2. Click **"Retry"** in UI
3. If repeats, click **"Reset"** and simplify project

---

#### Symptom: Process stalls mid-execution

**Detection**: UI shows "Last update: 300s ago"

**Solution**:
```bash
# Check Claude process
ps aux | grep claude  # macOS/Linux

# Check STATUS.md
tail STATUS.md

# If truly stuck, click "Cancel" and retry
```

---

### Problem: Questions Not Appearing

#### Symptom: Execution pauses but no questions shown

**Cause**: Questions file exists but UI hasn't detected it

**Solution**:
1. Manually open `Questions_For_You.md`
2. If questions exist, answer them there
3. Press Enter in Claude's terminal window
4. Or click **"Continue"** in UI

---

### Problem: Output Folder Empty

#### Symptom: "Project Complete!" but no files in output/

**Possible Causes**:
1. Plan had no output phases
2. Files generated in different location
3. Execution actually failed

**Diagnosis**:
```bash
# Check for generated files
find . -type f -mtime -1  # Files modified in last day

# Check progress.md for clues
cat docs/planning/progress.md
```

**Solution**:
- Review plan to see expected outputs
- Check if files were generated elsewhere in project
- Review STATUS.md for errors

---

### Problem: UI Not Updating

#### Symptom: UI shows "Disconnected" or stale state

**Cause**: SSE connection lost

**Solution 1 - Refresh page**:
- Press `F5` or `Cmd+R` to refresh browser
- SSE will reconnect automatically

**Solution 2 - Check browser console**:
- Press `F12` to open DevTools
- Check Console tab for errors
- Look for SSE connection errors

**Solution 3 - Check server logs**:
- Look at terminal where server is running
- Check for error messages

---

### Problem: File Upload Fails

#### Symptom: "Failed to upload files"

**Possible Causes**:
1. File too large
2. Permission issues
3. Disk full

**Solution**:
```bash
# Check file size
ls -lh file.csv

# Check disk space
df -h  # macOS/Linux
dir  # Windows

# Try smaller files or fewer at once
```

---

## Performance Optimization

### Reduce API Costs

**Use Lower-Tier Models**:
- Use **haiku** for documentation/formatting
- Use **sonnet** for most tasks (default)
- Reserve **opus** for complex architecture

**Enable Context Caching**:
- Use `delegation_mode: conservative` (default)
- Reuses context across phases

**Enable Validation**:
```yaml
validation:
  enabled: true
  confidence_threshold: 0.8
```
Simplifies plans for simple tasks, reducing API calls.

---

### Speed Up Execution

**Use Parallel Delegation** (costs more):
```yaml
execution:
  delegation_mode: parallel
```

**Disable Quality Gates** (faster, less safe):
```yaml
quality_gates:
  run_tests: false
  run_typecheck: false
  run_lint: false
```

---

## Security Considerations

### Running on Localhost Only

**Default**: Server binds to `127.0.0.1` (localhost only)

**Security**: Only accessible from local machine

**To expose on network** (NOT RECOMMENDED):
```python
# In app.py - DO NOT DO THIS unless you know what you're doing
app.run(host='0.0.0.0', port=8080)
```

**If exposing publicly**:
- Add authentication
- Use HTTPS
- Add rate limiting
- Validate all inputs
- Run in Docker container

---

### File Upload Security

**Current**: Files sanitized with `os.path.basename()` to prevent path traversal

**Good**:
```python
filename = os.path.basename(file.filename)  # "../../etc/passwd" becomes "passwd"
```

**Additional Hardening** (if needed):
- Validate file extensions
- Scan for malware
- Limit file sizes
- Sandbox file processing

---

## Maintenance

### Cleaning Up

**Archive Old Projects**:
- Use **"Start New Project"** button to auto-archive
- Or manually move folders from `archive/` to external storage

**Clear Output Folder**:
```bash
rm -rf output/*  # Keep .gitkeep
```

**Clear Planning Files**:
```bash
rm docs/planning/*.md  # Will be regenerated
```

---

### Backups

**Important Files to Back Up**:
- `config/project-config.json` - Your project config
- `File_References_For_Your_Project/` - Your reference materials
- `output/` - Generated deliverables
- `project.yaml` - System configuration

**Not Needed to Back Up**:
- `docs/planning/` - Regenerated each run
- `STATUS.md` - Ephemeral state
- `archive/` - Already archived projects

---

### Logs

**Server Logs**: Output to terminal where server is running

**Claude Logs**: Shown in Claude's terminal window

**To Save Logs**:
```bash
# Save server output
python server/app.py > server.log 2>&1

# Save Claude output (harder, requires no new console)
# Edit process_manager.py to remove CREATE_NEW_CONSOLE
```

---

## Advanced Deployment

### Running as a Service (Linux)

**systemd service** (`/etc/systemd/system/conductor.service`):
```ini
[Unit]
Description=Simple Claude Conductor Web UI
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/path/to/AIPM
ExecStart=/usr/bin/python3 server/app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

**Enable and start**:
```bash
sudo systemctl enable conductor
sudo systemctl start conductor
sudo systemctl status conductor
```

---

### Running with Nginx Reverse Proxy

**nginx config** (`/etc/nginx/sites-available/conductor`):
```nginx
server {
    listen 80;
    server_name conductor.local;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/events {
        proxy_pass http://127.0.0.1:8080/api/events;
        proxy_buffering off;
        proxy_cache off;
        proxy_set_header Connection '';
        proxy_http_version 1.1;
        chunked_transfer_encoding off;
    }
}
```

---

### Docker Deployment

**Dockerfile**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["python", "server/app.py"]
```

**docker-compose.yml**:
```yaml
version: '3.8'
services:
  conductor:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./config:/app/config
      - ./output:/app/output
      - ./archive:/app/archive
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
```

**Note**: Requires Claude CLI in container and proper authentication handling.

---

## Monitoring

### Health Check

**Endpoint**: `GET /health`

```bash
curl http://localhost:8080/health
```

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2026-01-26T10:00:00"
}
```

---

### Process Monitoring

**Check if server running**:
```bash
curl -s http://localhost:8080/health | jq .status
```

**Check if Claude running**:
```bash
curl -s http://localhost:8080/api/state | jq .claudeRunning
```

---

## Related Documentation

- [README.md](README.md) - Overview and quick start
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration options
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [API_REFERENCE.md](API_REFERENCE.md) - API endpoints
