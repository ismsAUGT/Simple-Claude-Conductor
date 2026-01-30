# Simple Claude Conductor

**Run Claude Code projects without touching the terminal.**

Simple Claude Conductor is a web-based GUI that wraps the Claude Code CLI, making AI-powered project development accessible to non-technical users. Configure your project, generate a plan, and let Claude build it - all from your browser.

---

## Features

- **Visual Project Configuration** - Name your project, describe what you want, and select a model (Haiku/Sonnet/Opus)
- **Drag-and-Drop Reference Files** - Upload sample files, templates, or screenshots for Claude to reference
- **One-Click Plan Generation** - Claude analyzes your requirements and creates a phased execution plan
- **Planning Questions Workflow** - Claude can ask clarifying questions before building (optional)
- **Real-Time Progress Tracking** - Watch Claude's progress via live updates in your browser
- **State Persistence** - Survives server restarts; resume where you left off

---

## Quick Start

### Prerequisites

1. **Python 3.8+** - [Download Python](https://www.python.org/downloads/) (check "Add Python to PATH" during install)
2. **Claude Code CLI** - Install and log in:
   ```bash
   npm install -g @anthropic-ai/claude-code
   claude login
   ```

### Installation

1. **Download or clone this project**
2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

### Running the Conductor

**Windows:**
Double-click `START_CONDUCTOR.bat`

**Mac/Linux:**
```bash
python server/app.py
```

Then open **http://localhost:8080** in your browser.

---

## How It Works

1. **Configure** - Enter your project name and describe what you want to build
2. **Add References** (optional) - Upload sample files, mockups, or documentation
3. **Generate Plan** - Click the button and Claude creates a phased execution plan
4. **Answer Questions** (if enabled) - Respond to any clarifying questions from Claude
5. **Execute Plan** - Click execute and Claude builds your project phase by phase
6. **Review Deliverables** - Find your generated files in the `output/` folder

---

## Project Structure

```
Simple-Claude-Conductor/
├── server/                           # Flask backend + Alpine.js frontend
│   ├── app.py                        # Main server (30+ API endpoints)
│   ├── state_manager.py              # State machine with persistence
│   ├── process_manager.py            # Claude subprocess management
│   └── templates/conductor.html      # Web UI
├── docs/                             # Documentation and planning files
├── config/                           # Project configuration
├── File_References_For_Your_Project/ # Your reference files (drag-and-drop)
├── output/                           # Generated deliverables
├── archive/                          # Past project runs
├── .claude/                          # Claude Code configuration
├── CLAUDE.md                         # Workflow instructions for Claude
├── STATUS.md                         # State persistence file
├── START_CONDUCTOR.bat               # Windows launcher
└── requirements.txt                  # Python dependencies
```

---

## Configuration Options

### Model Selection

| Model | Best For | Cost |
|-------|----------|------|
| **Haiku** | Simple tasks, documentation | Lowest |
| **Sonnet** | Standard development (recommended) | Medium |
| **Opus** | Complex architecture, debugging | Highest |

### Planning Questions

Toggle in the UI to enable/disable Claude's ability to ask clarifying questions before generating the plan. When enabled, you'll see a "Questions" step where you can provide answers or skip to let Claude make assumptions.

### Reference Files

Drop files into the upload area or the `File_References_For_Your_Project/` folder:
- Sample data files
- Screenshots of desired layouts
- Documentation to follow
- Code examples to mimic

---

## Troubleshooting

### "Claude not found" or "claude is not recognized"

Install the Claude Code CLI and authenticate:
```bash
npm install -g @anthropic-ai/claude-code
claude login
```

### "Port 8080 already in use"

Either:
- Stop the existing process using port 8080
- Or edit `server/app.py` to change the port number

### State seems stuck or out of sync

1. Check `STATUS.md` for the current state
2. Try restarting the server (close terminal, run `START_CONDUCTOR.bat` again)
3. If needed, reset the project from the UI

### Server won't start (Python issues)

Ensure Python and dependencies are installed:
```bash
python --version          # Should be 3.8+
pip install -r requirements.txt
```

---

## Technical Details

- **Backend**: Flask with Server-Sent Events (SSE) for real-time updates
- **Frontend**: Alpine.js (no build step required)
- **State**: Persisted in `STATUS.md` via YAML frontmatter
- **Process**: Claude runs as a subprocess with proper PID tracking

For detailed technical documentation, see [docs/SimpleClaudeConductorDocumentation/](docs/SimpleClaudeConductorDocumentation/).

---

## License

MIT License - Use freely for personal or commercial projects.

---

## Support

- **Issues**: Report bugs or request features via the project repository
- **Claude Code Help**: https://github.com/anthropics/claude-code


## SCC Asks for your initial Prompt

<img width="297" height="442" alt="image" src="https://github.com/user-attachments/assets/5a25c7e7-31fc-42d6-af25-159005fede2a" />

## SCC Asks for seed files to reference and learn from

<img width="424" height="257" alt="image" src="https://github.com/user-attachments/assets/a4337a23-3f14-46a6-a3b3-7eec0f78aeaf" />

## SCC Generates a Plan

<img width="434" height="420" alt="image" src="https://github.com/user-attachments/assets/d1ff1111-3124-486d-a69c-b2ae8dcc0512" />

## SCC Asks clarifying questions (if needed)

<img width="406" height="357" alt="image" src="https://github.com/user-attachments/assets/9ec7b245-e53a-400c-b6c7-9206819dd2e3" />

## SCC Executes the plan, spinning up parallel agents to manage context windows

<img width="477" height="286" alt="image" src="https://github.com/user-attachments/assets/ee5d0906-7bf8-43d9-ba67-8a33b62659f4" />

