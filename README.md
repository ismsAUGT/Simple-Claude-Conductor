# Claude Project Executor

A reusable project template that transforms Claude into an intelligent project execution engine. Describe what you want to build, and Claude generates a plan, asks clarifying questions, executes phases with optimal model selection, and produces an executive summary.

## Features

- **Intelligent Plan Generation** - Describe your goal; Claude creates a structured plan with phases
- **Automatic Model Selection** - Uses Haiku for simple tasks, Sonnet for standard work, Opus for complex problems
- **Fresh Agents Per Phase** - Each phase gets a clean context, preventing degradation
- **Persistent Memory** - Planning files maintain context across sessions
- **Safety Hooks** - Branch protection, file organization guards, research reminders
- **Executive Summaries** - Automated reports on completion

## Prerequisites

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
├── .claude/
│   ├── README.md                    # System overview
│   ├── instructions.md              # Core principles
│   ├── workflow-guide.md            # Agent patterns
│   ├── settings.local.json          # Hook config
│   ├── hooks/                       # Safety hooks
│   └── skills/                      # Skill definitions
├── docs/planning/
│   ├── task-plan.md                 # Master plan
│   ├── findings.md                  # Research findings
│   ├── progress.md                  # Session history
│   ├── references.md                # File catalog
│   ├── reports/                     # Generated reports
│   └── archive/                     # Completed projects
├── project.yaml                     # Configuration
├── project-init.sh                  # Setup script
├── CLAUDE.md                        # Quick reference
└── README.md                        # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - See LICENSE file for details.

## Support

- **Issues**: https://github.com/your-org/claude-project-executor/issues
- **Documentation**: See `.claude/` folder for detailed guides
- **Claude Code Help**: https://github.com/anthropics/claude-code
# Simple-Claude-Conductor
