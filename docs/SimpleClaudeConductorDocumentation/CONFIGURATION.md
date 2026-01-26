# Configuration

This document describes configuration file formats and settings for the Simple Claude Conductor Web UI.

## Configuration Files

The system uses two main configuration files:

1. **project.yaml** - System-level settings (in project root)
2. **project-config.json** - User project configuration (in config/)

## project.yaml

**Location**: `project.yaml` (project root)

**Purpose**: System-level configuration for Simple Claude Conductor workflow

**Format**: YAML

### Full Schema

```yaml
# Project metadata
project:
  name: Simple Claude Conductor
  version: v4.0

# Execution settings
execution:
  default_model: sonnet              # haiku | sonnet | opus
  delegation_mode: conservative      # conservative | parallel
  interrupt_for_questions: false     # Ask questions during planning
  bypass_permissions: true           # Skip permission prompts
  test_first: false                  # TDD mode (write tests first)

# Quality settings
quality_gates:
  run_tests: false                   # Run tests before phase completion
  run_typecheck: false               # Run type checking
  run_lint: false                    # Run linting

# Validation settings (quick validation before planning)
validation:
  enabled: true                      # Enable quick validation
  confidence_threshold: 0.8          # 80% confidence to simplify plan
  skip_keywords:                     # Skip validation for these tasks
    - architecture
    - security
    - complex

# Iteration settings (quick iteration after execution)
iteration:
  enabled: true                      # Enable quick iteration
  error_threshold: 0.1               # Run correction if >10% errors
  skip_keywords:                     # Skip iteration for these tasks
    - draft
    - prototype
    - quick

# Safety limits
limits:
  max_files_per_phase: 20            # Max files created per phase
  max_iterations_per_task: 5         # Max iterations per task
  stop_on_repeated_errors: 3         # Stop after N repeated errors
  max_total_files: 100               # Cap total files created
```

### Field Descriptions

#### project
**name**: Project name (string)

**version**: Version identifier (string)

---

#### execution

##### default_model
**Type**: string

**Values**:
- `haiku` - Fast, cheap model for simple tasks (docs, formatting)
- `sonnet` - Balanced model for standard implementation
- `opus` - Powerful model for complex tasks (architecture, security)

**Default**: `sonnet`

**Usage**: The Web UI uses this to populate the model dropdown in configuration form.

---

##### delegation_mode
**Type**: string

**Values**:
- `conservative` - Execute phases in main session (reuse cache)
- `parallel` - Spawn subagent per phase (faster but more expensive)

**Default**: `conservative`

**Usage**: Determines whether Claude spawns subagents for phases or executes in-session.

---

##### interrupt_for_questions
**Type**: boolean

**Default**: `false`

**Usage**:
- `true` - Write questions to Questions_For_You.md and wait for user
- `false` - Make assumptions and document them

**Web UI**: When `true`, execution pauses at questions state for user input.

---

##### bypass_permissions
**Type**: boolean

**Default**: `true`

**Usage**: Skip permission prompts for Bash commands. Useful for non-interactive execution.

---

##### test_first
**Type**: boolean

**Default**: `false`

**Usage**: TDD mode - write tests before implementation.

---

#### quality_gates

##### run_tests
**Type**: boolean

**Default**: `false`

**Usage**: Run test suite before marking phase complete. Blocks completion if tests fail.

---

##### run_typecheck
**Type**: boolean

**Default**: `false`

**Usage**: Run TypeScript type checking before phase completion.

---

##### run_lint
**Type**: boolean

**Default**: `false`

**Usage**: Run linting before phase completion.

---

#### validation

##### enabled
**Type**: boolean

**Default**: `true`

**Usage**: Run quick validation on 5-10 sample items before generating full plan.

**Behavior**: If confidence >= threshold, generates simplified 1-2 phase plan.

---

##### confidence_threshold
**Type**: float (0.0 to 1.0)

**Default**: `0.8` (80%)

**Usage**: Minimum confidence from validation to use simplified plan.

---

##### skip_keywords
**Type**: list of strings

**Default**: `["architecture", "security", "complex"]`

**Usage**: Skip validation if goal contains these keywords.

---

#### iteration

##### enabled
**Type**: boolean

**Default**: `true`

**Usage**: Self-check sample outputs after execution and run correction pass if needed.

---

##### error_threshold
**Type**: float (0.0 to 1.0)

**Default**: `0.1` (10%)

**Usage**: Run correction pass if error rate in sample exceeds this threshold.

---

##### skip_keywords
**Type**: list of strings

**Default**: `["draft", "prototype", "quick"]`

**Usage**: Skip iteration if goal contains these keywords.

---

#### limits

##### max_files_per_phase
**Type**: integer

**Default**: `20`

**Usage**: Maximum files created in a single phase. Prevents runaway generation.

---

##### max_iterations_per_task
**Type**: integer

**Default**: `5`

**Usage**: Maximum iteration loops per task. Prevents infinite loops.

---

##### stop_on_repeated_errors
**Type**: integer

**Default**: `3`

**Usage**: Stop execution if same error occurs N times in a row.

---

##### max_total_files
**Type**: integer

**Default**: `100`

**Usage**: Maximum total files created across all phases.

---

## project-config.json

**Location**: `config/project-config.json`

**Purpose**: User project configuration (set via Web UI)

**Format**: JSON

### Schema

```json
{
  "projectName": "string",
  "projectDescription": "string",
  "defaultModel": "string"
}
```

### Fields

#### projectName
**Type**: string

**Required**: Yes (via UI validation)

**Usage**: Displayed in UI, used for archive folder names

**Example**: `"Task Management Dashboard"`

---

#### projectDescription
**Type**: string

**Required**: Yes (via UI validation)

**Usage**: Main prompt sent to Claude for plan generation

**Example**:
```json
"projectDescription": "Build a task management dashboard with drag-and-drop boards, task filtering, and due date reminders. Should support multiple projects and collaborative features."
```

**Best Practices**:
- Be specific about features
- Mention technologies if you have preferences
- Describe expected outputs
- Include any constraints

---

#### defaultModel
**Type**: string

**Values**: `"haiku"` | `"sonnet"` | `"opus"`

**Default**: `"sonnet"` (from project.yaml)

**Usage**: Model selection for plan generation and execution

**Model Selection Guide**:
- **haiku** - Simple tasks (docs, formatting, data processing)
- **sonnet** - Standard implementation (most web apps, APIs)
- **opus** - Complex tasks (architecture, security, optimization)

---

## Environment Variables

The Flask server doesn't use environment variables, but Claude CLI does:

### ANTHROPIC_API_KEY

**Purpose**: Claude API authentication

**Set By**: `claude login` command

**Location**: Stored in Claude CLI config (not in project)

**Usage**: Required for Claude to function

---

## Model Selection

### When to Use Each Model

#### Haiku (Fast & Cheap)
**Use For**:
- Documentation generation
- File formatting (JSON, CSV, Markdown)
- Simple data transformations
- Template generation
- File organization

**Cost**: ~$0.25 per million input tokens

---

#### Sonnet (Balanced)
**Use For**:
- Web application development
- REST API implementation
- Database schema design
- Testing and validation
- Standard refactoring

**Cost**: ~$3 per million input tokens

**Default Choice**: Best balance of quality and cost for most tasks.

---

#### Opus (Powerful)
**Use For**:
- System architecture design
- Security-critical implementations
- Complex algorithms
- Performance optimization
- Multi-system integration

**Cost**: ~$15 per million input tokens

**Note**: Use sparingly for tasks that truly need it.

---

## Directory Structure

```
AIPM/
├── project.yaml                    # System configuration
├── config/
│   └── project-config.json         # User project config (created by UI)
├── STATUS.md                       # State (YAML frontmatter)
├── Questions_For_You.md            # Questions from Claude
├── File_References_For_Your_Project/
│   └── [user-uploaded files]       # Reference materials
├── docs/
│   └── planning/
│       ├── task-plan.md            # Generated plan
│       ├── findings.md             # Research notes
│       ├── progress.md             # Session history
│       └── references.md           # File catalog
├── output/
│   ├── [generated deliverables]    # Output files
│   └── cost_report.md              # Cost tracking
└── archive/
    └── [timestamp]_[project_name]/ # Archived projects
```

## Configuration Workflow

### 1. Server Reads project.yaml

On startup, Flask reads system configuration:
```python
# Not explicitly read by Flask, but exists for Claude
```

---

### 2. User Configures Project (Web UI)

User fills form:
- Project Name
- Project Description
- Model Selection
- Upload reference files

On "Generate Plan" click:
```javascript
await api.saveConfig({
    projectName: 'My Project',
    projectDescription: 'Build a...',
    defaultModel: 'sonnet'
});
await api.generatePlan();
```

---

### 3. Flask Saves project-config.json

```python
@app.route('/api/config', methods=['POST'])
def save_config():
    config = request.json
    config_path = os.path.join(PROJECT_ROOT, 'config', 'project-config.json')
    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)

    # Transition to configured state
    state_manager.set_state('configured')
    return jsonify({'success': True})
```

---

### 4. Claude Reads Configuration

When plan generation starts, Claude:
1. Reads project.yaml for system settings
2. Reads project-config.json for user's project details
3. Reads File_References_For_Your_Project/ for context

---

## Configuration Best Practices

### System Configuration (project.yaml)

1. **Use Conservative Delegation**: Reduces cost, reuses cache
2. **Enable Validation**: Catches issues early for simple tasks
3. **Enable Iteration**: Improves quality with self-correction
4. **Set Safety Limits**: Prevents runaway generation
5. **Disable Quality Gates**: Unless you have tests set up

---

### Project Configuration (project-config.json)

1. **Descriptive Names**: Use clear, specific project names
2. **Detailed Descriptions**: More detail = better plans
3. **Right Model**: Don't use Opus for simple tasks
4. **Reference Files**: Upload examples, templates, data samples

**Good Description**:
```
Build a REST API for a blog platform with these features:
- User authentication (JWT)
- CRUD operations for posts and comments
- Markdown support for post content
- SQLite database
- Python/Flask implementation
- OpenAPI/Swagger documentation
```

**Bad Description**:
```
Make me a blog API
```

---

## Advanced Configuration

### Custom Validation Rules

Edit project.yaml to customize validation:
```yaml
validation:
  enabled: true
  confidence_threshold: 0.9  # Require 90% confidence
  skip_keywords:
    - architecture
    - security
    - complex
    - multi-service  # Custom keyword
```

---

### Custom Safety Limits

```yaml
limits:
  max_files_per_phase: 50    # Increase for large projects
  max_total_files: 500       # Increase limit
  stop_on_repeated_errors: 5 # More tolerance
```

---

### Disable All Quality Gates

```yaml
quality_gates:
  run_tests: false
  run_typecheck: false
  run_lint: false
```

---

## Troubleshooting Configuration

### Problem: Plans Are Too Simple

**Solution**: Lower validation confidence threshold
```yaml
validation:
  confidence_threshold: 0.6  # Accept lower confidence
```

---

### Problem: Plans Are Too Complex

**Solution**: Enable validation for more tasks
```yaml
validation:
  skip_keywords: []  # Don't skip any tasks
```

---

### Problem: Running Out of Context

**Solution**: Use delegation mode
```yaml
execution:
  delegation_mode: parallel  # Spawn subagents per phase
```

---

### Problem: Too Many Files Generated

**Solution**: Lower limits
```yaml
limits:
  max_files_per_phase: 10
  max_total_files: 50
```

---

## Configuration Migration

### From v3.0 to v4.0

Changes:
- Added `validation` section
- Added `iteration` section
- Changed `default_model` location (now in `execution`)

**Old Format**:
```yaml
default_model: sonnet
```

**New Format**:
```yaml
execution:
  default_model: sonnet
```

---

## Related Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Installation and setup
- [ARCHITECTURE.md](ARCHITECTURE.md) - How configuration is used
- [FRONTEND.md](FRONTEND.md) - UI configuration form
