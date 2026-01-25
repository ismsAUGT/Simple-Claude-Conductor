# Simple Claude Conductor: UI Overhaul Plan

## Executive Summary

Transform the current file-based workflow into a simple local web UI that guides non-technical users through each step without requiring them to remember commands or navigate complex markdown files.

---

## Current Pain Points (Discovery Findings)

### 1. Project Reset
- No clear way to archive old work
- Users might lose previous project files
- No visibility into what files will be cleared

### 2. Configuration (START_HERE.md)
- 149 lines of markdown to read through
- Easy to miss fields (buried in explanatory text)
- Manual text replacement (`_____` blanks)
- Two duplicate "Step 5" sections (bug)
- No validation of inputs
- Reference files mentioned but hard to manage

### 3. Initialization (INITIALIZE_MY_PROJECT.bat)
- Batch terminal is unfamiliar to non-technical users
- "Do you need to sign in?" question is confusing (users don't know)
- No clear feedback if something fails
- Multi-step confirmation flow

### 4. Running (RUN_PROJECT.bat)
- Users must **remember** to type "Generate a plan"
- Users must **remember** to type "Execute the plan"
- No visibility into progress without opening STATUS.md manually
- Questions in Questions_For_You.md require file switching
- No clear state machine (what step am I on?)

### 5. Mental Model Gap
- Users don't understand the workflow stages
- No single place to see "where am I in the process"
- Terminal output scrolls away quickly

---

## Proposed Solution: Local Web UI

A single HTML file with embedded JavaScript that:
1. Runs locally (no server needed - uses `file://` protocol or minimal local server)
2. Communicates with the filesystem via simple mechanisms
3. Guides users through a clear step-by-step workflow
4. Polls for status updates (every 3-5 seconds when active)

### Technology Choice: Portable Python Bundle

**Approach**: Self-contained bundle with embedded Python + Flask web server

**Why this approach**:
- **Zero installs for users** - Just extract and double-click
- **Works on any Windows machine** - No Python/Node install required
- **Full filesystem access** - Python handles all file operations
- **Clean HTTP API** - Browser communicates via fetch()
- **~50MB download** - Acceptable size for full functionality

**How it works**:
```
┌─────────────────────────────────────────────────────────────────────┐
│  User's Machine                                                      │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Simple-Claude-Conductor/ (extracted folder)                  │   │
│  │                                                                │   │
│  │  ┌─────────────┐     ┌─────────────────────────────────────┐  │   │
│  │  │ Browser     │◀───▶│  python-portable/                   │  │   │
│  │  │ localhost   │     │  └─ server/app.py (Flask)           │  │   │
│  │  │ :8080       │     │     ├─ Serves UI                    │  │   │
│  │  └─────────────┘     │     ├─ File read/write API          │  │   │
│  │                      │     ├─ Spawns Claude process        │  │   │
│  │                      │     └─ Polls STATUS.md              │  │   │
│  │                      └─────────────────────────────────────┘  │   │
│  │                                      │                         │   │
│  │                                      ▼                         │   │
│  │  ┌─────────────────────────────────────────────────────────┐  │   │
│  │  │  Project Files                                          │  │   │
│  │  │  ├─ File_References_For_Your_Project/ (user input)     │  │   │
│  │  │  ├─ output/ (generated files)                          │  │   │
│  │  │  ├─ docs/planning/ (internal state)                    │  │   │
│  │  │  ├─ STATUS.md (progress tracking)                      │  │   │
│  │  │  └─ archive/ (old projects)                            │  │   │
│  │  └─────────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Safety: Comprehensive Permissions Instead of Bypass

Instead of `--dangerously-skip-permissions`, we use a comprehensive `settings.local.json` that pre-approves all expected operations.

**Benefits**:
- Explicit allow list (know exactly what's permitted)
- Explicit deny list (dangerous operations blocked)
- No bypass needed (Claude runs smoothly)
- Learning over time (add new patterns as discovered)

**See**: [COMPREHENSIVE_PERMISSIONS.md](COMPREHENSIVE_PERMISSIONS.md) for full list.

**Handling Unexpected Prompts**:
- UI detects stall (no STATUS.md update for 60+ seconds)
- Shows notification: "Claude may need permission - check terminal"
- User approves in terminal
- We log the operation and add to allow list over time

---

## Workflow Stages

The UI presents 5 clear stages:

```
┌─────────┐    ┌───────────┐    ┌────────────┐    ┌───────────┐    ┌─────────┐
│ 1.Reset │───▶│ 2.Configure│───▶│ 3.Initialize│───▶│ 4.Generate│───▶│ 5.Execute│
│ (opt)   │    │            │    │             │    │   Plan    │    │   Plan  │
└─────────┘    └───────────┘    └────────────┘    └───────────┘    └─────────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │ 4b.Questions│
                                                  │   (if any)  │
                                                  └─────────────┘
```

---

## Detailed Feature Specifications

### Stage 0: Project Reset (Optional)

**UI Elements**:
- "Start Fresh" button (collapsible section, not prominent)
- Preview of what will be archived/cleared
- Archive folder with dated subfolders

**Archive Structure**:
```
archive/
├── 2024-01-25_1430_MyProject/
│   ├── docs/planning/          (task-plan, findings, progress, references)
│   ├── output/                 (generated files)
│   ├── Questions_For_You.md
│   ├── STATUS.md
│   └── START_HERE.md           (original config)
├── 2024-01-24_0900_OtherProject/
│   └── ...
└── .gitkeep
```

**Behavior**:
- Archives are timestamped with project name
- Claude's `.gitignore` and `CLAUDE.md` updated to exclude `archive/` from searches
- User can browse old archives from UI (read-only list)

---

### Stage 1: Configure Project

**UI Elements**:

```
┌─────────────────────────────────────────────────────────────────┐
│  CONFIGURE YOUR PROJECT                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Authentication                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ ○ Claude Pro/Max Subscription  [Check Login Status]     │    │
│  │ ○ API Key: [________________________]                   │    │
│  └─────────────────────────────────────────────────────────┘    │
│  Status: ✓ Logged in as user@email.com                          │
│                                                                  │
│  Project Details                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Project Name: [_______________________________]         │    │
│  │                                                          │    │
│  │ What do you want to build?                              │    │
│  │ ┌──────────────────────────────────────────────────┐    │    │
│  │ │                                                    │    │    │
│  │ │ (Large text area for description)                 │    │    │
│  │ │                                                    │    │    │
│  │ └──────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Reference Files                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Files in File_References_For_Your_Project/:             │    │
│  │   • sample_template.docx                                │    │
│  │   • api_docs.pdf                                        │    │
│  │   • screenshot.png                                      │    │
│  │                                                          │    │
│  │ [Open Folder] [Refresh List]                            │    │
│  │                                                          │    │
│  │ Drag files here to add ─────────────────────────────    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Options (click to expand)                                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Ask clarifying questions? [Yes ▼]                       │    │
│  │ Default AI model:         [Sonnet ▼]                    │    │
│  │                                                          │    │
│  │ Advanced (for developers):                              │    │
│  │   Run tests?    [No ▼]                                  │    │
│  │   Type check?   [No ▼]                                  │    │
│  │   Lint?         [No ▼]                                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [Review Prompt Quality]  (Optional - checks your       │    │
│  │   description for clarity and completeness)             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│                              [Save & Continue →]                 │
└─────────────────────────────────────────────────────────────────┘
```

**"Check Login Status" Button**:
- Runs `claude --version` and checks for auth
- Shows clear status: "Logged in" / "Not logged in" / "Claude not installed"
- If not logged in, shows "Log In" button that runs `claude login`

**"Review Prompt Quality" Button**:
- Spawns a quick Claude call (haiku model) to review the prompt
- Returns suggestions like:
  - "Consider adding more detail about the expected output format"
  - "Your description mentions 'the API' but doesn't specify which one"
  - "Looks good! Your description is clear and detailed."

**Reference Files Section**:
- Lists files currently in `File_References_For_Your_Project/`
- "Open Folder" opens Windows Explorer to that folder
- Drag-and-drop zone (if browser supports `file://` drag - may need workaround)

---

### Stage 2: Initialize

**UI Elements**:
```
┌─────────────────────────────────────────────────────────────────┐
│  INITIALIZE PROJECT                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Ready to set up: "My Awesome Project"                          │
│                                                                  │
│  This will:                                                      │
│    ✓ Create project configuration (project.yaml)                │
│    ✓ Set up status tracking (STATUS.md)                         │
│    ✓ Prepare question file (Questions_For_You.md)               │
│    ✓ Configure Claude trust settings                            │
│                                                                  │
│                         [Initialize Project]                     │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  Progress:                                                       │
│    [████████████████████████████░░] 80%                          │
│    ✓ Configuration created                                       │
│    ✓ Status file created                                         │
│    ✓ Questions file created                                      │
│    ⟳ Setting up trust... (this may take a moment)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Behavior**:
- Single button click
- Shows progress as each step completes
- Auto-advances to next stage when done

---

### Stage 3: Generate Plan

**UI Elements**:
```
┌─────────────────────────────────────────────────────────────────┐
│  GENERATE PLAN                                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Claude will analyze your project description and create        │
│  a step-by-step plan for building it.                           │
│                                                                  │
│                       [Generate Plan]                            │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  Status: ⟳ Working...                                            │
│  Started: 2:30 PM                                                │
│  Elapsed: 2 min 15 sec                                           │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Last update from Claude:                                 │    │
│  │ "Analyzing project requirements and creating phases..."  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [View Full Status] (opens STATUS.md)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**After Plan Generated**:
```
┌─────────────────────────────────────────────────────────────────┐
│  PLAN GENERATED ✓                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Your plan has 5 phases:                                         │
│                                                                  │
│    Phase 1: Research and Setup                                   │
│    Phase 2: Core Implementation                                  │
│    Phase 3: User Interface                                       │
│    Phase 4: Testing                                              │
│    Phase 5: Documentation                                        │
│                                                                  │
│  [View Full Plan] (opens task-plan.md)                          │
│                                                                  │
│                     [Continue to Execute →]                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Status Polling**:
- Reads `STATUS.md` every 3 seconds
- Parses "WHAT TO DO NEXT" section for current state
- Shows elapsed time since last update
- Detects when plan generation is complete

---

### Stage 3b: Answer Questions (Conditional)

**Only shown if** Claude has questions AND user selected "Ask clarifying questions: Yes"

**UI Elements**:
```
┌─────────────────────────────────────────────────────────────────┐
│  CLAUDE HAS QUESTIONS                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Before proceeding, Claude needs some clarification:            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Question 1: Target Platform                              │    │
│  │                                                          │    │
│  │ Should this run on:                                      │    │
│  │ ○ Web browser only                                       │    │
│  │ ○ Desktop application                                    │    │
│  │ ○ Both web and desktop                                   │    │
│  │                                                          │    │
│  │ Your answer: [_________________________________]         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Question 2: Data Storage                                 │    │
│  │                                                          │    │
│  │ How should user data be stored?                          │    │
│  │                                                          │    │
│  │ Your answer: [_________________________________]         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [Skip - Let Claude Decide]        [Submit Answers]              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Behavior**:
- Parses `Questions_For_You.md` to extract questions
- Writes answers back to file
- "Skip" leaves answers blank (Claude makes assumptions)

---

### Stage 4: Execute Plan

**UI Elements**:
```
┌─────────────────────────────────────────────────────────────────┐
│  EXECUTE PLAN                                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Progress: Phase 2 of 5                                          │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ [████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 40%     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Phases:                                                         │
│    ✓ Phase 1: Research and Setup          (Complete)            │
│    ⟳ Phase 2: Core Implementation         (In Progress)         │
│    ○ Phase 3: User Interface              (Pending)             │
│    ○ Phase 4: Testing                     (Pending)             │
│    ○ Phase 5: Documentation               (Pending)             │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  Current Activity:                                               │
│  "Building the main application logic..."                        │
│                                                                  │
│  Started: 2:45 PM                                                │
│  Phase elapsed: 5 min 32 sec                                     │
│  Last update: 12 seconds ago                                     │
│                                                                  │
│  [View Full Status] [View Terminal Output]                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Completion**:
```
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT COMPLETE! ✓                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  All 5 phases completed successfully.                            │
│                                                                  │
│  Output Files:                                                   │
│    • output/main.py                                              │
│    • output/utils.py                                             │
│    • output/README.md                                            │
│                                                                  │
│  [Open Output Folder]                                            │
│                                                                  │
│  Session Cost: ~$0.45                                            │
│  [View Full Report]                                              │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  What's Next?                                                    │
│    • Review the generated files in output/                       │
│    • Run "Continue" if you want to make changes                  │
│    • Click "Start New Project" to begin something new            │
│                                                                  │
│  [Start New Project]                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Implementation Architecture

### File Structure

```
Simple-Claude-Conductor/
│
├── START_CONDUCTOR.bat         # Double-click to launch (opens browser + starts server)
├── STOP_CONDUCTOR.bat          # Graceful shutdown
│
├── python-portable/            # Embedded Python (~40MB)
│   ├── python.exe
│   ├── pythonw.exe
│   └── Lib/
│       └── site-packages/
│           └── flask/          # Pre-installed
│
├── server/                     # Flask application
│   ├── app.py                  # Main server
│   ├── routes/
│   │   ├── api.py              # REST endpoints
│   │   └── claude.py           # Claude process management
│   ├── templates/
│   │   └── conductor.html      # Main UI
│   └── static/
│       ├── css/
│       └── js/
│
├── config/                     # User configuration (persists across sessions)
│   ├── project-config.json     # Current project settings
│   └── conductor-state.json    # UI state
│
├── File_References_For_Your_Project/   # User's input files
│   └── .gitkeep
│
├── output/                     # Generated files
│   └── .gitkeep
│
├── archive/                    # Archived old projects
│   └── .gitkeep
│
├── docs/planning/              # Internal planning files
│   ├── task-plan.md
│   ├── findings.md
│   ├── progress.md
│   └── references.md
│
├── STATUS.md                   # Progress tracking
├── Questions_For_You.md        # Claude's questions
│
├── .claude/                    # Claude Code configuration
│   ├── settings.local.json     # Comprehensive permissions
│   ├── hooks/                  # Workflow hooks
│   └── skills/                 # Custom skills
│
├── project.yaml                # Project configuration
├── CLAUDE.md                   # Instructions for Claude
└── README.md                   # User documentation
```

### Server Architecture (app.py)

```python
from flask import Flask, render_template, jsonify, request
import subprocess
import os
import json
import threading
import time

app = Flask(__name__)

# State tracking
claude_process = None
last_status_check = None

@app.route('/')
def index():
    return render_template('conductor.html')

# ============ Configuration API ============

@app.route('/api/config', methods=['GET'])
def get_config():
    """Read current project configuration"""
    config_path = 'config/project-config.json'
    if os.path.exists(config_path):
        with open(config_path) as f:
            return jsonify(json.load(f))
    return jsonify({})

@app.route('/api/config', methods=['POST'])
def save_config():
    """Save project configuration"""
    config = request.json
    with open('config/project-config.json', 'w') as f:
        json.dump(config, f, indent=2)
    return jsonify({'success': True})

# ============ Status API ============

@app.route('/api/status')
def get_status():
    """Read STATUS.md and parse current state"""
    status = {'raw': '', 'phase': 0, 'total': 0, 'activity': '', 'state': 'unknown'}

    if os.path.exists('STATUS.md'):
        with open('STATUS.md') as f:
            content = f.read()
            status['raw'] = content

            # Parse phase info
            import re
            phase_match = re.search(r'Phase (\d+) of (\d+)', content)
            if phase_match:
                status['phase'] = int(phase_match.group(1))
                status['total'] = int(phase_match.group(2))

            # Detect state
            if 'Complete' in content and status['phase'] == status['total']:
                status['state'] = 'complete'
            elif 'Questions_For_You.md' in content:
                status['state'] = 'questions'
            elif status['phase'] > 0:
                status['state'] = 'executing'
            elif 'Plan Generated' in content:
                status['state'] = 'planned'
            else:
                status['state'] = 'ready'

    status['claude_running'] = claude_process is not None and claude_process.poll() is None
    return jsonify(status)

# ============ Reference Files API ============

@app.route('/api/references')
def list_references():
    """List files in reference folder"""
    ref_dir = 'File_References_For_Your_Project'
    files = []
    if os.path.exists(ref_dir):
        for f in os.listdir(ref_dir):
            if not f.startswith('.'):
                path = os.path.join(ref_dir, f)
                files.append({
                    'name': f,
                    'size': os.path.getsize(path),
                    'isDir': os.path.isdir(path)
                })
    return jsonify(files)

# ============ Claude Control API ============

@app.route('/api/claude/check')
def check_claude():
    """Check if Claude is installed and logged in"""
    try:
        result = subprocess.run(['claude', '--version'], capture_output=True, text=True, timeout=5)
        installed = result.returncode == 0

        # Check login status
        result = subprocess.run(['claude', 'config', 'get', 'primaryEmail'],
                              capture_output=True, text=True, timeout=5)
        email = result.stdout.strip() if result.returncode == 0 else None

        return jsonify({
            'installed': installed,
            'loggedIn': email is not None,
            'email': email
        })
    except Exception as e:
        return jsonify({'installed': False, 'error': str(e)})

@app.route('/api/claude/login', methods=['POST'])
def login_claude():
    """Trigger Claude login"""
    subprocess.Popen(['claude', 'login'], creationflags=subprocess.CREATE_NEW_CONSOLE)
    return jsonify({'success': True, 'message': 'Login window opened'})

@app.route('/api/claude/generate-plan', methods=['POST'])
def generate_plan():
    """Start Claude to generate a plan"""
    global claude_process
    claude_process = subprocess.Popen(
        ['claude', '-p', 'Generate a plan'],
        cwd=os.getcwd(),
        creationflags=subprocess.CREATE_NEW_CONSOLE
    )
    return jsonify({'success': True, 'pid': claude_process.pid})

@app.route('/api/claude/execute-plan', methods=['POST'])
def execute_plan():
    """Start Claude to execute the plan"""
    global claude_process
    claude_process = subprocess.Popen(
        ['claude', '-p', 'Execute the plan'],
        cwd=os.getcwd(),
        creationflags=subprocess.CREATE_NEW_CONSOLE
    )
    return jsonify({'success': True, 'pid': claude_process.pid})

@app.route('/api/claude/continue', methods=['POST'])
def continue_claude():
    """Continue after answering questions"""
    global claude_process
    claude_process = subprocess.Popen(
        ['claude', '-p', 'Continue'],
        cwd=os.getcwd(),
        creationflags=subprocess.CREATE_NEW_CONSOLE
    )
    return jsonify({'success': True, 'pid': claude_process.pid})

# ============ Archive API ============

@app.route('/api/archive', methods=['POST'])
def archive_project():
    """Archive current project to timestamped folder"""
    from datetime import datetime
    import shutil

    timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
    project_name = request.json.get('projectName', 'project').replace(' ', '_')
    archive_name = f"{timestamp}_{project_name}"
    archive_path = os.path.join('archive', archive_name)

    os.makedirs(archive_path, exist_ok=True)

    # Move relevant files
    files_to_archive = [
        'docs/planning',
        'output',
        'STATUS.md',
        'Questions_For_You.md',
        'config/project-config.json'
    ]

    for f in files_to_archive:
        if os.path.exists(f):
            dest = os.path.join(archive_path, f)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if os.path.isdir(f):
                shutil.copytree(f, dest)
            else:
                shutil.copy2(f, dest)

    return jsonify({'success': True, 'archivePath': archive_path})

# ============ Questions API ============

@app.route('/api/questions')
def get_questions():
    """Parse Questions_For_You.md"""
    questions = []
    if os.path.exists('Questions_For_You.md'):
        with open('Questions_For_You.md') as f:
            content = f.read()
            # Parse question blocks (simplified)
            # Real implementation would be more robust
            import re
            blocks = re.findall(r'### Question \d+:.*?\n\n(.*?)\n\n\*\*Your Answer:\*\*',
                              content, re.DOTALL)
            questions = [{'text': q.strip(), 'answer': ''} for q in blocks]
    return jsonify(questions)

@app.route('/api/questions', methods=['POST'])
def save_answers():
    """Write answers back to Questions_For_You.md"""
    answers = request.json.get('answers', [])
    # Format and write back
    content = "# Questions For You\n\n"
    for i, a in enumerate(answers):
        content += f"### Question {i+1}: Question\n\n"
        content += f"{a['text']}\n\n"
        content += f"**Your Answer:** {a['answer']}\n\n"

    with open('Questions_For_You.md', 'w') as f:
        f.write(content)
    return jsonify({'success': True})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080, debug=False)
```

### START_CONDUCTOR.bat

```batch
@echo off
title Simple Claude Conductor
cd /d "%~dp0"

echo.
echo ========================================
echo   Simple Claude Conductor
echo ========================================
echo.
echo Starting web interface...
echo.

:: Start server in background
start /b python-portable\python.exe server\app.py

:: Wait a moment for server to start
timeout /t 2 /nobreak >nul

:: Open browser
start http://localhost:8080

echo.
echo Conductor is running at: http://localhost:8080
echo.
echo Press Ctrl+C to stop the server.
echo.

:: Keep window open (server runs in background of this process)
pause >nul
```

### conductor-state.json

Tracks current workflow state:

```json
{
  "currentStage": "execute",
  "projectName": "My Project",
  "initialized": true,
  "planGenerated": true,
  "planPhases": 5,
  "phasesCompleted": 2,
  "questionsAnswered": true,
  "lastUpdated": "2024-01-25T14:30:00Z",
  "claudeProcessPid": 12345,
  "lastStatusUpdate": "2024-01-25T14:29:45Z"
}
```

---

## Status Polling Mechanism

### How It Works

1. **UI starts a background task** via batch/Python
2. **Claude runs in a separate process**
3. **Claude updates STATUS.md** as it works (already does this)
4. **UI polls STATUS.md** every 3-5 seconds
5. **UI parses STATUS.md** to extract:
   - Current phase
   - Progress percentage (from "X of Y phases complete")
   - Current activity (from "WHAT TO DO NEXT" section)
   - Last update timestamp

### Parsing STATUS.md

```javascript
function parseStatus(content) {
  const lines = content.split('\n');

  // Extract phase info
  const phaseMatch = content.match(/Phase (\d+) of (\d+)/);
  const current = phaseMatch ? parseInt(phaseMatch[1]) : 0;
  const total = phaseMatch ? parseInt(phaseMatch[2]) : 0;

  // Extract current activity
  const whatNextSection = content.match(/## 👉 WHAT TO DO NEXT[\s\S]*?(?=---|\n## )/);
  const activity = whatNextSection ? whatNextSection[0].trim() : '';

  // Detect state
  const isComplete = content.includes('Complete') && current === total;
  const hasQuestions = content.includes('Questions_For_You.md');

  return { current, total, activity, isComplete, hasQuestions };
}
```

---

## CLAUDE.md Updates

Add to CLAUDE.md to exclude archive from searches:

```markdown
## Archive Folder

The `archive/` folder contains old project files from previous runs.

**IMPORTANT**:
- Do NOT read files from `archive/` - they are historical only
- Do NOT include `archive/` in Grep/Glob searches
- This saves context and avoids confusion with old project files

When searching, exclude archive:
- Glob: Don't use patterns that match `archive/**`
- Grep: Use `--glob '!archive/**'` or skip archive paths
```

---

## Migration Path

### For Existing Users

1. **First run of new UI** detects old-style project:
   - If `project.yaml` exists with data, offer to migrate
   - Show: "We found an existing project. Archive it or continue?"

2. **Batch files remain functional**:
   - Users who prefer command line can still use them
   - UI is additive, not replacing

### For New Users

1. **Download/clone repo**
2. **Open conductor.html** (or double-click)
3. **Follow the wizard**

---

## Resolved Decisions

| Decision | Resolution |
|----------|------------|
| Docker vs Portable Python | **Portable Python** - Zero installs, ~50MB download |
| Bypass permissions | **Comprehensive allow list** - Pre-approve all expected operations |
| Archive browsing | **No browsing needed** - Just notify user of archive location |
| Prompt quality review | **Include it** - Quick Claude call for feedback |
| Output folder location | **Inside project folder** - `output/` stays where it is |

## Open Questions

### Technical

1. **Portable Python source**
   - Where to get a reliable portable Python bundle?
   - Options: WinPython, embeddable Python from python.org, custom build
   - Need: Python 3.9+, pip, Flask pre-installed

2. **Claude process management**
   - How to reliably detect when Claude finishes?
   - Options: Poll for process, check for "done" file, watch STATUS.md
   - Current plan: Poll `subprocess.poll()` + STATUS.md changes

3. **Reference file drag-and-drop**
   - Browser security may block dropping files to arbitrary paths
   - Fallback: "Open Folder" button, user copies files manually
   - Nice-to-have, not critical

### UX

1. **What if user closes browser mid-execution?**
   - Claude keeps running (separate process)
   - On reload: Detect running process, resume UI state
   - Show: "Execution in progress - reconnecting..."

2. **Multiple browser tabs?**
   - Should we prevent multiple tabs from conflicting?
   - Simple solution: Show warning "Already open in another tab"

3. **Dark mode?**
   - Nice to have but not priority
   - Could add later with CSS toggle

---

## Phased Implementation

### Phase 1: Infrastructure & Portable Python Bundle
**Priority: HIGHEST - Foundation for everything else**

- [ ] Create portable Python bundle structure
- [ ] Set up Flask server skeleton (app.py)
- [ ] Implement START_CONDUCTOR.bat and STOP_CONDUCTOR.bat
- [ ] Test browser auto-launch
- [ ] Verify Claude CLI detection from server
- [ ] Create comprehensive settings.local.json (permissions)
- [ ] Test uninterrupted plan execution with new permissions

**Deliverables**:
- Working `python-portable/` bundle
- Server that starts and serves a "Hello World" page
- Claude can run without permission interruptions

### Phase 2: Archive/Reset Flow & Guardrails
**Priority: HIGH - Enables clean project lifecycle**

- [ ] Define strict folder structure (input/output locations)
- [ ] Implement archive API (`/api/archive`)
- [ ] Create archive folder structure with timestamps
- [ ] Update CLAUDE.md to exclude archive from searches
- [ ] Implement reset flow (archive old, create fresh)
- [ ] Add notification: "Old files moved to archive/[timestamp]/"
- [ ] Update .gitignore for archive folder

**Guardrails**:
| Folder | Purpose | Who Can Write |
|--------|---------|---------------|
| `File_References_For_Your_Project/` | User input files | User only |
| `config/` | Project configuration | UI only |
| `output/` | Generated files | Claude only |
| `archive/` | Old projects | UI only (on reset) |
| `docs/planning/` | Internal state | Claude only |

**Deliverables**:
- Archive button in UI
- Clear folder ownership rules
- Claude ignores archive/ in all searches

### Phase 3: Configuration Form
**Priority: MEDIUM - Core user experience**

- [ ] Design HTML form layout
- [ ] Implement config read/write API
- [ ] Add authentication check (`/api/claude/check`)
- [ ] Add login trigger (`/api/claude/login`)
- [ ] List reference files (`/api/references`)
- [ ] Open reference folder button
- [ ] Dropdown menus for options (model, questions, etc.)
- [ ] Form validation
- [ ] "Review Prompt Quality" button (spawns quick Claude call)
- [ ] Save & Continue flow

**Deliverables**:
- Complete configuration form
- No more editing START_HERE.md manually
- Prompt quality review feature

### Phase 4: Status Polling & Progress Display
**Priority: MEDIUM - User visibility**

- [ ] Implement status API (`/api/status`)
- [ ] Parse STATUS.md for phase info
- [ ] Detect state (ready/planned/executing/questions/complete)
- [ ] Polling every 3 seconds during execution
- [ ] Progress bar visualization
- [ ] Phase list with checkmarks
- [ ] Elapsed time display
- [ ] "Last update: X seconds ago"
- [ ] Stall detection (>60s no update = possible permission prompt)
- [ ] Permission interruption notification

**Deliverables**:
- Live progress display
- User always knows what's happening
- Alert when Claude might need attention

### Phase 5: Question Integration
**Priority: LOWER - Enhancement**

- [ ] Implement questions API (`/api/questions`)
- [ ] Parse Questions_For_You.md format
- [ ] Render questions as inline form
- [ ] Write answers back to file
- [ ] "Skip - Let Claude Decide" button
- [ ] Auto-detect when questions appear
- [ ] Transition to question stage automatically

**Deliverables**:
- No more file switching for questions
- Seamless Q&A flow in UI

### Phase 6: Polish & Edge Cases
**Priority: LOWEST - Nice to have**

- [ ] Error handling for all API endpoints
- [ ] Graceful shutdown (STOP_CONDUCTOR.bat)
- [ ] Keyboard shortcuts
- [ ] Better styling/animations
- [ ] "View Terminal Output" option
- [ ] Cost report display after completion
- [ ] "Open Output Folder" button
- [ ] Session persistence across browser refresh

---

## Success Criteria

1. **Non-technical user can complete a project without**:
   - Opening a terminal manually
   - Editing markdown files
   - Remembering any commands
   - Switching between multiple files

2. **User always knows**:
   - What stage they're in
   - What's happening right now
   - What to do next
   - If something went wrong

3. **Zero new dependencies** (in MVP):
   - No Node.js required
   - No Python required (for basic functionality)
   - Just a browser

---

## Next Steps

1. **Validate this plan** - Review and confirm approach ✓
2. **Source portable Python** - Find/create embeddable Python bundle with Flask
3. **Build Phase 1** - Infrastructure & server skeleton
4. **Test permissions** - Run full plan execution with new allow list
5. **Build remaining phases** - Sequential implementation
6. **User testing** - Get feedback from non-technical coworkers

---

## Appendix: File References

- [COMPREHENSIVE_PERMISSIONS.md](COMPREHENSIVE_PERMISSIONS.md) - Full permissions allow/deny lists
- [UI_OVERHAUL_PLAN.md](UI_OVERHAUL_PLAN.md) - This document
