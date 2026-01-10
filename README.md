# Simple Claude Conductor

**Build software projects with Claude AI - even if you can't code!**

## What Is This?

Simple Claude Conductor is a project template that lets **non-technical users** build complete software projects using Claude AI. Just describe what you want in plain English, and Claude does the rest - planning, coding, testing, and documentation.

### The Problem

You have an idea for a website, app, or tool, but:
- ❌ You don't know how to code
- ❌ Hiring developers is expensive
- ❌ Existing tools are too limited or complex
- ❌ You're not sure where to start

### The Solution

Simple Claude Conductor gives you a **personal AI developer** that:
- ✓ Understands your requirements in plain English
- ✓ Creates a detailed plan and asks clarifying questions
- ✓ Writes all the code, tests, and documentation
- ✓ Guides you step-by-step with clear status updates
- ✓ Produces ready-to-use files in the `output/` folder

**No coding knowledge required. No command-line experience needed. Just fill out a form and run two files.**

---

## Super Quick Start (Impatient Users)

**3 minutes to start building:**

1. Fill out [START_HERE.md](START_HERE.md) (your project details)
2. Double-click `INITIALIZE_MY_PROJECT.bat`
3. Double-click `RUN_PROJECT.bat` and type "Generate a plan"

Done! Claude is now building your project. Check [STATUS.md](STATUS.md) for progress.

---

## How It Works

1. **You describe** what you want in [START_HERE.md](START_HERE.md)
2. **Claude plans** the project in phases
3. **Claude builds** each phase automatically
4. **You get** finished files in the `output/` folder

Throughout the process:
- Check [STATUS.md](STATUS.md) to see what's happening
- Answer questions in [Questions_For_You.md](Questions_For_You.md) when Claude needs input
- Add reference files to `File_References_For_Your_Project/` if helpful

---

## What Can You Build?

**Websites**: Landing pages, portfolios, blogs, e-commerce sites
**Web Apps**: Dashboards, task managers, booking systems
**Backend APIs**: REST APIs, GraphQL, database systems
**Automation**: Scripts, data processing, report generation
**Documentation**: Project wikis, API docs, user guides

---

## Key Features

### For Non-Technical Users
- **📝 Fill-in-the-Blank Setup** - No configuration files, just answer simple questions in [START_HERE.md](START_HERE.md)
- **📍 Always Know What's Next** - [STATUS.md](STATUS.md) always shows "WHAT TO DO NEXT" at the top
- **💬 Plain English Questions** - Claude writes questions to [Questions_For_You.md](Questions_For_You.md) instead of asking in terminal
- **📂 Reference File Support** - Add examples, docs, or screenshots to `File_References_For_Your_Project/` and Claude uses them
- **🎯 Progress Tracking** - See exactly what's done, what's in progress, and what's coming

### For Everyone
- **🧠 Intelligent Planning** - Claude generates structured, multi-phase plans
- **⚡ Smart Model Selection** - Uses fast models for simple tasks, powerful ones for complex work
- **🔄 Fresh Context Per Phase** - Prevents AI degradation with clean agents for each phase
- **💾 Persistent Memory** - Planning files maintain context across sessions
- **🛡️ Safety Gates** - Optional tests, type checking, and linting before marking phases complete
- **📊 Cost Reports** - Automatic token usage and cost tracking after each session

---

## What Files Do I Use?

**For Non-Technical Users**: Here's what you need to know about the files in this project.

### Files YOU Interact With

These are the only files you need to touch:

| File/Folder | What It's For | When to Use It |
|-------------|---------------|----------------|
| [START_HERE.md](START_HERE.md) | Fill-in-the-blank form for your project | **FIRST** - Fill this out before anything else |
| `INITIALIZE_MY_PROJECT.bat` | Setup script | **SECOND** - Double-click this after filling START_HERE.md |
| `RUN_PROJECT.bat` | Starts Claude | **EVERY TIME** - Run this to work with Claude |
| [STATUS.md](STATUS.md) | Project progress report | **ANYTIME** - Check this to see what's done |
| [Questions_For_You.md](Questions_For_You.md) | Claude's questions for you | **WHEN PROMPTED** - Claude writes questions here |
| [output/](output/) | Your finished project files | **AT THE END** - Check here for generated files |
| [File_References_For_Your_Project/](File_References_For_Your_Project/) | *Optional*: Add sample files, docs, or examples here | **BEFORE RUNNING** - If you have reference materials |

### Files You DON'T Need to Touch

These files make the system work - **you can ignore them**:

- `.claude/` - Claude CLI configuration (system files)
- `docs/planning/` - Planning files Claude uses internally
- `scripts/` - Python scripts for reports
- `project.yaml` - Configuration file (auto-generated)
- `CLAUDE.md` - Instructions for Claude (not for you)
- `.git/`, `.gitignore` - Version control files
- `Bootstrap/` - Setup files

**Simple rule**: If it's not in the first table above, you don't need to touch it!

---

## Detailed Quick Start (Windows Users)

**Step-by-step guide for first-time users:**

### Step 1: Download
Download this project (click "Code" → "Download ZIP" on GitHub, then unzip to a folder)

### Step 2: Fill Out Your Project Details
Open [START_HERE.md](START_HERE.md) and fill in the blanks:
- Whether you have a Claude subscription or API key
- Your project name
- **Most importantly**: Describe what you want to build in detail!
  - Example: "Build a simple website with a contact form that sends emails. It should have a homepage, about page, and be mobile-friendly."

### Step 3: Optional - Add Reference Files
Have examples, screenshots, or documentation? Put them in `File_References_For_Your_Project/`
- Claude will automatically read and use them as reference

### Step 4: Initialize
Double-click `INITIALIZE_MY_PROJECT.bat`
- This sets everything up for you
- If using a subscription, a browser will open to log you in
- Takes about 30 seconds

### Step 5: Start Building!
Double-click `RUN_PROJECT.bat`
- Claude starts in a terminal window
- Type: **"Generate a plan"**
- Claude creates a plan and shows it to you
- Type: **"Execute the plan"**
- Claude starts building!

### Step 6: Stay Informed
**While Claude works**, you can:
- Check [STATUS.md](STATUS.md) anytime - it always shows what's happening and what to do next
- Answer questions in [Questions_For_You.md](Questions_For_You.md) if Claude needs input
- Watch the terminal to see progress in real-time

### Step 7: Get Your Files
When done, find your completed project in the `output/` folder!

**Pro tip:** [STATUS.md](STATUS.md) has a "👉 WHAT TO DO NEXT" section at the top that always tells you exactly what to do. Check it anytime you're unsure!

---

## Prerequisites (Technical Setup)

### 1. Install Claude Code CLI

Claude Code is Anthropic's official command-line interface for Claude. Install it via npm:

```bash
npm install -g @anthropic-ai/claude-code
```

Or if you prefer using npx (no installation required):
```bash
npx @anthropic-ai/claude-code
```

### 2. Authentication

Claude Code requires authentication. You have two options:

**Option A: Anthropic API Key (Recommended for automation)**
```bash
# Set your API key as an environment variable
export ANTHROPIC_API_KEY="your-api-key-here"

# On Windows (PowerShell)
$env:ANTHROPIC_API_KEY="your-api-key-here"

# On Windows (Command Prompt)
set ANTHROPIC_API_KEY=your-api-key-here
```

Get your API key from: https://console.anthropic.com/api-keys

**Option B: Claude Pro/Max Subscription**
If you have a Claude Pro or Max subscription, you can authenticate via browser:
```bash
claude login
```

### 3. Verify Installation

```bash
claude --version
```

## Installation

### Option 1: Clone the Template (Recommended)

```bash
# Clone this repository
git clone https://github.com/your-org/claude-project-executor.git my-project
cd my-project

# Remove the git history to start fresh
rm -rf .git
git init
```

### Option 2: Copy to Existing Project

```bash
# Copy the template files to your existing project
cp -r claude-project-executor/.claude your-project/
cp -r claude-project-executor/docs your-project/
cp claude-project-executor/project.yaml your-project/
cp claude-project-executor/project-init.sh your-project/
cp claude-project-executor/CLAUDE.md your-project/
```

## Quick Start

### 1. Initialize the Project

```bash
cd my-project
./project-init.sh
```

You'll be prompted for:
- **Project name**: Display name for your project
- **Default model**: `haiku` | `sonnet` | `opus` (sonnet recommended)
- **Bypass permissions**: `true` for autonomous execution, `false` for confirmations
- **Interrupt for questions**: `true` to clarify before executing, `false` to proceed with assumptions

### 2. Start Claude Code

```bash
claude
```

### 3. Provide Your Prompt

Simply describe what you want to build:

```
Build a REST API for user management with JWT authentication
```

Claude will:
1. Generate a structured plan with phases
2. Ask clarifying questions (if enabled)
3. Execute each phase with optimal model selection
4. Update planning files as work progresses
5. Generate an executive summary when complete

## Example Prompts

### Web Development

```
Build a React dashboard with:
- User authentication (login/logout)
- Data visualization using Chart.js
- Dark mode toggle
- Responsive design for mobile
```

```
Create a Next.js e-commerce storefront with:
- Product catalog with filtering
- Shopping cart functionality
- Stripe checkout integration
- Order history page
```

### Backend/API Development

```
Build a REST API for a task management system:
- User registration and authentication
- CRUD operations for tasks and projects
- Team collaboration features
- PostgreSQL database with Prisma ORM
```

```
Create a GraphQL API for a blog platform:
- Posts, comments, and categories
- User roles (admin, author, reader)
- Image upload support
- Full-text search
```

### DevOps/Infrastructure

```
Set up a CI/CD pipeline for this Node.js project:
- GitHub Actions workflows
- Automated testing on PR
- Docker containerization
- Deployment to AWS ECS
```

```
Create Terraform infrastructure for a microservices architecture:
- VPC with public/private subnets
- EKS cluster with autoscaling
- RDS PostgreSQL database
- Application Load Balancer
```

### Refactoring/Migration

```
Refactor the authentication system to use OAuth2:
- Support Google and GitHub providers
- Migrate existing users
- Maintain backwards compatibility
- Add comprehensive tests
```

```
Migrate this Express.js API to TypeScript:
- Convert all JavaScript files
- Add type definitions
- Set up strict TypeScript config
- Update build process
```

### Data/ML Projects

```
Build a data pipeline for customer analytics:
- Ingest data from S3
- Transform and clean with pandas
- Store in PostgreSQL
- Generate daily reports
```

## Configuration

### project.yaml

```yaml
version: "1.0"

project:
  name: "My Project"
  description: "Project description"

execution:
  default_model: "sonnet"           # haiku | sonnet | opus
  bypass_permissions: false          # Skip confirmations
  interrupt_for_questions: true      # Ask before executing
  max_auto_phases: 5                 # Max phases without pause
  generate_summary: true             # Auto-generate summary
  test_first: false                  # TDD mode (write tests first)

quality_gates:
  run_tests: false                   # Run tests before phase complete
  typecheck: false                   # Run type checker
  lint: false                        # Run linter

models:
  low: "haiku"                       # Simple tasks
  medium: "sonnet"                   # Standard tasks
  high: "opus"                       # Complex tasks

paths:
  planning_dir: "docs/planning"
  reports_dir: "docs/planning/reports"
  archive_dir: "docs/planning/archive"

hooks:
  mcp_reminder: true                 # MCP-First reminder
  branch_protection: true            # Block dangerous git ops
  file_guard: true                   # Warn on ad-hoc files
  findings_reminder: true            # 2-Action Rule reminder
```

### Recommended Settings by Use Case

**Autonomous Execution (Experienced Users)**
```yaml
execution:
  bypass_permissions: true
  interrupt_for_questions: false
  max_auto_phases: 10
```

**Guided Execution (Learning/Reviewing)**
```yaml
execution:
  bypass_permissions: false
  interrupt_for_questions: true
  max_auto_phases: 3
```

**Cost-Optimized (Budget-Conscious)**
```yaml
execution:
  default_model: "haiku"
models:
  low: "haiku"
  medium: "haiku"
  high: "sonnet"
```

**Quality-Focused (TDD + Gates)**
```yaml
execution:
  test_first: true
quality_gates:
  run_tests: true
  typecheck: true
  lint: true
```

## Quality Gates

Quality gates are optional validation steps that run before marking a phase complete.

### Supported Checks

| Check | Auto-detects |
|-------|--------------|
| **Tests** | npm test, pytest, go test, cargo test, mvn test |
| **Typecheck** | tsc, mypy, pyright, go build, cargo check |
| **Lint** | eslint, ruff, flake8, golangci-lint, cargo clippy |

### Configuration

```yaml
quality_gates:
  run_tests: true    # Run project tests
  typecheck: true    # Run type checking
  lint: false        # Run linter (optional)
```

### How It Works

1. Claude completes phase implementation
2. Enabled quality gates run automatically
3. If any gate fails, Claude fixes the issues
4. Phase only marked complete when all gates pass

## Test-First Development (TDD)

Enable test-driven development for implementation phases.

### Configuration

```yaml
execution:
  test_first: true

quality_gates:
  run_tests: true    # Required for TDD
```

### TDD Flow

When enabled, implementation phases follow **RED → GREEN → REFACTOR**:

1. **RED**: Write failing tests that define expected behavior
2. **GREEN**: Write minimal code to make tests pass
3. **REFACTOR**: Clean up while keeping tests green

### When TDD Applies

- Implementation phases (keywords: implement, build, create)
- Medium and High complexity phases
- Skips documentation, config, and research phases

## Key Commands

Once Claude is running, use these commands:

| Command | Description |
|---------|-------------|
| `Generate a plan for [description]` | Start planning |
| `Execute the plan` | Begin phase execution |
| `Show progress` | View current status |
| `Continue from where we left off` | Resume interrupted work |
| `Summarize` | Generate executive summary |
| `Archive the project` | Move to archive folder |

## Planning Files

All context is maintained in `docs/planning/`:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `task-plan.md` | Goal, phases, decisions, risks | Major decisions |
| `findings.md` | Research discoveries, patterns | Every 2 research ops |
| `progress.md` | Session history, completed work | End of session/phase |
| `references.md` | File catalog, resources | When files found |

## Core Principles

These principles are enforced by hooks and embedded in Claude's instructions:

1. **Fresh Agents, Persistent Files** - Each phase spawns a new agent; files carry context
2. **2-Action Rule** - Update `findings.md` every 2 research operations
3. **Stub → Review → Implement** - Structure before code
4. **3-Strike Protocol** - Try 3 approaches before escalating
5. **MCP-First** - Use MCP tools before Grep/Glob for file discovery
6. **Minimal Implementation** - Only build what's requested

## Model Selection

The system automatically selects the optimal model based on task complexity:

| Complexity | Model | Cost | Use Cases |
|------------|-------|------|-----------|
| Low | Haiku | $0.25/M tokens | Docs, formatting, simple file ops |
| Medium | Sonnet | $3/M tokens | Implementation, testing, refactoring |
| High | Opus | $15/M tokens | Architecture, security, debugging |

### Complexity Scoring

Phases are scored based on:
- **Keywords**: "architecture" → High, "implement" → Medium, "format" → Low
- **File count**: 10+ files → High, 5-10 → Medium, 1-4 → Low
- **Explicit override**: `**Model**: Opus` in task-plan.md

## Troubleshooting

### "Command not found: claude"
```bash
# Ensure npm bin is in your PATH
export PATH="$PATH:$(npm bin -g)"

# Or use npx
npx @anthropic-ai/claude-code
```

### "Invalid API key"
```bash
# Check your API key is set
echo $ANTHROPIC_API_KEY

# Re-set if needed
export ANTHROPIC_API_KEY="sk-ant-..."
```

### "Planning files not found"
```bash
# Re-initialize planning files
bash .claude/skills/planning-with-files/scripts/init-planning.sh "Project Name"
```

### "Hooks not executing"
```bash
# Make hooks executable
chmod +x .claude/hooks/*.sh
chmod +x .claude/skills/*/scripts/*.sh
```

### Session Interrupted
Simply restart Claude and say:
```
Continue from where we left off
```
Claude will read the planning files and resume.

## Project Structure

```
project-root/
├── START_HERE.md                    # 👤 USER: Fill-in-the-blank form
├── INITIALIZE_MY_PROJECT.bat        # 👤 USER: Run once to setup
├── RUN_PROJECT.bat                  # 👤 USER: Run to start Claude
├── README.md                        # 👤 USER: This documentation
│
├── File_References_For_Your_Project/  # 👤 USER: Optional reference files
│   └── README.md                    # Instructions for this folder
│
├── STATUS.md                        # 👤 USER: Check progress & next steps
├── Questions_For_You.md             # 👤 USER: Answer Claude's questions
│
├── output/                          # 👤 USER: Generated project files
│
├── .claude/                         # ⚙️  SYSTEM: Claude CLI config
│   ├── instructions.md              # Core principles
│   ├── workflow-guide.md            # Agent patterns
│   ├── settings.local.json          # Hook config
│   ├── hooks/                       # Safety hooks
│   └── skills/                      # Skill definitions
│
├── docs/
│   ├── planning/                    # ⚙️  SYSTEM: Planning files
│   │   ├── task-plan.md             # Master plan
│   │   ├── findings.md              # Research findings
│   │   ├── progress.md              # Session history
│   │   └── references.md            # File catalog
│   └── STATUS_EXAMPLES.md           # Status format examples
│
├── scripts/
│   └── generate_cost_report.py      # ⚙️  SYSTEM: Cost tracking
│
├── project.yaml                     # ⚙️  SYSTEM: Auto-generated config
├── CLAUDE.md                        # ⚙️  SYSTEM: Instructions for Claude
└── .gitignore                       # ⚙️  SYSTEM: Git configuration

Legend:
👤 USER - Files you interact with
⚙️  SYSTEM - Files you don't need to touch
```

## Frequently Asked Questions

### Do I need to know how to code?
**No!** This tool is specifically designed for non-technical users. If you can describe what you want in plain English, Claude can build it.

### How much does this cost?
You need either:
- **Claude Pro/Max subscription** (~$20-40/month) - Easiest option
- **API access** (pay-per-use) - Usually $1-5 per project depending on complexity

The tool shows cost estimates after each session.

### What if I get stuck?
1. Check [STATUS.md](STATUS.md) - it always shows "WHAT TO DO NEXT"
2. Check [docs/STATUS_EXAMPLES.md](docs/STATUS_EXAMPLES.md) for examples
3. Check this README for detailed instructions

### Can I pause and resume later?
Yes! Your progress is automatically saved. Just run `RUN_PROJECT.bat` again and type "Continue".

### What if Claude asks me something I don't know?
Just press Enter in the terminal. Claude will make a reasonable assumption and keep going.

### Can I use this for commercial projects?
Yes! MIT License - use it however you want.

### Where do the generated files go?
Everything Claude creates goes in the `output/` folder.

### How do I add examples for Claude to follow?
Put them in `File_References_For_Your_Project/` before running. Claude automatically reads them.

---

## What's New (Recent Updates)

### Version 2.0 - Enhanced User Experience
- ✓ **Dynamic Status Tracking** - [STATUS.md](STATUS.md) always shows "WHAT TO DO NEXT"
- ✓ **Reference File Support** - Add examples to `File_References_For_Your_Project/`
- ✓ **Clearer Documentation** - "What Files Do I Use?" section with visual tables
- ✓ **Better Guidance** - Step-by-step instructions throughout
- ✓ **Example Library** - [docs/STATUS_EXAMPLES.md](docs/STATUS_EXAMPLES.md) with 7 scenarios

---

## Contributing

This project is open source and welcomes contributions!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Ideas for contributions:
- Additional example projects
- Better error handling
- Support for more languages/frameworks
- UI improvements

---

## License

MIT License - Use it however you want, even for commercial projects!

---

## Support & Resources

- **Questions?** Open an issue at the project repository
- **Claude Code Help**: https://github.com/anthropics/claude-code
- **Need debugging help?** Include your [STATUS.md](STATUS.md) and `output/cost_report.md` when asking

---

**Ready to build something amazing? Start with [START_HERE.md](START_HERE.md)!** 🚀
