"""
Simple Claude Conductor - Web UI Server

A Flask server that provides a web interface for managing Claude Code projects.
Designed for non-technical users who need a GUI instead of terminal commands.
"""

from flask import Flask, render_template, jsonify, request, send_from_directory
import subprocess
import os
import sys
import json
import re
import signal
from datetime import datetime

# Add the project root to path for imports
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(PROJECT_ROOT)

app = Flask(__name__,
            template_folder='templates',
            static_folder='static')

# Global state
claude_process = None

# ============ Error Handlers ============

@app.errorhandler(Exception)
def handle_exception(e):
    """Global error handler for unhandled exceptions"""
    app.logger.error(f'Unhandled exception: {str(e)}')
    return jsonify({
        'success': False,
        'error': str(e),
        'type': type(e).__name__
    }), 500

@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return jsonify({
        'success': False,
        'error': 'Endpoint not found'
    }), 404

# ============ Main Routes ============

@app.route('/')
def index():
    """Serve the main conductor UI"""
    return render_template('conductor.html')

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'timestamp': datetime.now().isoformat()})

# ============ Configuration API ============

@app.route('/api/config', methods=['GET'])
def get_config():
    """Read current project configuration"""
    config_path = os.path.join(PROJECT_ROOT, 'config', 'project-config.json')
    if os.path.exists(config_path):
        with open(config_path, 'r', encoding='utf-8') as f:
            return jsonify(json.load(f))
    return jsonify({})

@app.route('/api/config', methods=['POST'])
def save_config():
    """Save project configuration"""
    config = request.json
    config_path = os.path.join(PROJECT_ROOT, 'config', 'project-config.json')
    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)
    return jsonify({'success': True})

@app.route('/api/prompt/review', methods=['POST'])
def review_prompt():
    """Analyze prompt quality and provide feedback"""
    description = request.json.get('description', '')

    if not description.strip():
        return jsonify({'success': False, 'error': 'No description provided'})

    # Simple heuristic-based prompt quality check
    feedback_items = []
    quality = 'good'

    # Check length
    word_count = len(description.split())
    if word_count < 10:
        feedback_items.append('• <strong>Too short:</strong> Try adding more detail about what you want to build')
        quality = 'needs_work'
    elif word_count < 30:
        feedback_items.append('• Consider adding more specific details about features and requirements')

    # Check for specificity indicators
    specificity_words = ['should', 'must', 'need', 'want', 'require', 'include', 'feature', 'function', 'button', 'page', 'form', 'api', 'database', 'user']
    has_specificity = any(word in description.lower() for word in specificity_words)
    if not has_specificity:
        feedback_items.append('• <strong>Be more specific:</strong> Mention specific features, functions, or requirements')
        quality = 'needs_work'

    # Check for output format hints
    output_words = ['file', 'output', 'generate', 'create', 'build', 'make', 'produce', 'return', 'display', 'show']
    has_output_hint = any(word in description.lower() for word in output_words)
    if not has_output_hint:
        feedback_items.append('• Consider specifying what the expected output should look like')

    # Check for technology mentions
    tech_words = ['python', 'javascript', 'html', 'css', 'react', 'flask', 'node', 'api', 'json', 'sql', 'database']
    has_tech = any(word in description.lower() for word in tech_words)
    if has_tech:
        feedback_items.append('✓ Good: You mentioned specific technologies')

    # Check for constraints
    constraint_words = ['only', 'must not', 'should not', 'avoid', 'limit', 'maximum', 'minimum', 'constraint', 'requirement']
    has_constraints = any(word in description.lower() for word in constraint_words)
    if has_constraints:
        feedback_items.append('✓ Good: You included constraints or limitations')

    # Generate final feedback
    if quality == 'good' and len(feedback_items) <= 2:
        feedback = '<strong>✓ Your prompt looks good!</strong><br><br>' + '<br>'.join(feedback_items) if feedback_items else '<strong>✓ Your prompt looks good!</strong><br>It has enough detail for Claude to understand what you want to build.'
    else:
        feedback = '<strong>Suggestions to improve your prompt:</strong><br><br>' + '<br>'.join(feedback_items)

    return jsonify({
        'success': True,
        'quality': quality,
        'feedback': feedback
    })

# ============ Status API ============

@app.route('/api/status')
def get_status():
    """Read STATUS.md and parse current state"""
    global claude_process

    status = {
        'raw': '',
        'phase': 0,
        'total': 0,
        'activity': '',
        'state': 'unknown',
        'lastUpdated': None
    }

    status_path = os.path.join(PROJECT_ROOT, 'STATUS.md')
    if os.path.exists(status_path):
        with open(status_path, 'r', encoding='utf-8') as f:
            content = f.read()
            status['raw'] = content

            # Parse phase info (e.g., "Phase 2 of 5")
            phase_match = re.search(r'Phase (\d+) of (\d+)', content)
            if phase_match:
                status['phase'] = int(phase_match.group(1))
                status['total'] = int(phase_match.group(2))

            # Parse last updated time
            updated_match = re.search(r'\*\*Last Updated\*\*:\s*(.+)', content)
            if updated_match:
                status['lastUpdated'] = updated_match.group(1).strip()

            # Extract "WHAT TO DO NEXT" section
            next_match = re.search(r'## 👉 WHAT TO DO NEXT\s*\n\n(.+?)(?=\n---|\n##|$)', content, re.DOTALL)
            if next_match:
                status['activity'] = next_match.group(1).strip()

            # Detect state
            if 'Phases Completed' in content:
                completed_match = re.search(r'Phases Completed\s*\|\s*(\d+)\s*/\s*(\d+)', content)
                if completed_match:
                    completed = int(completed_match.group(1))
                    total = int(completed_match.group(2))
                    if completed == total and total > 0:
                        status['state'] = 'complete'
                    elif 'Questions_For_You.md' in status['activity']:
                        status['state'] = 'questions'
                    elif 'Executing' in content or 'In Progress' in content:
                        status['state'] = 'executing'
                    elif 'Plan Generated' in content or status['total'] > 0:
                        status['state'] = 'planned'
                    else:
                        status['state'] = 'ready'

            # Check for plan existence
            if 'Plan Generated | Yes' in content:
                status['planGenerated'] = True
            else:
                status['planGenerated'] = False

    # Check if Claude is running
    status['claudeRunning'] = claude_process is not None and claude_process.poll() is None

    return jsonify(status)

# ============ Reference Files API ============

@app.route('/api/references')
def list_references():
    """List files in reference folder"""
    ref_dir = os.path.join(PROJECT_ROOT, 'File_References_For_Your_Project')
    files = []
    if os.path.exists(ref_dir):
        for f in os.listdir(ref_dir):
            if not f.startswith('.'):
                path = os.path.join(ref_dir, f)
                files.append({
                    'name': f,
                    'size': os.path.getsize(path) if os.path.isfile(path) else 0,
                    'isDir': os.path.isdir(path)
                })
    return jsonify(files)

@app.route('/api/references/open')
def open_references_folder():
    """Open the reference files folder in Explorer"""
    ref_dir = os.path.join(PROJECT_ROOT, 'File_References_For_Your_Project')
    os.makedirs(ref_dir, exist_ok=True)

    if sys.platform == 'win32':
        os.startfile(ref_dir)
    elif sys.platform == 'darwin':
        subprocess.run(['open', ref_dir])
    else:
        subprocess.run(['xdg-open', ref_dir])

    return jsonify({'success': True})

# ============ Questions API ============

@app.route('/api/questions')
def get_questions():
    """Parse Questions_For_You.md and return questions as JSON"""
    questions_path = os.path.join(PROJECT_ROOT, 'Questions_For_You.md')
    questions = []
    has_questions = False

    if os.path.exists(questions_path):
        with open(questions_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if there are actual questions (not just the empty template)
        if '### Question' in content:
            has_questions = True

            # Parse questions using regex
            # Pattern matches: ### Question N: Topic\n[question text]\n\n**Your Answer:** [answer]
            pattern = r'### Question (\d+):\s*(.+?)\n(.+?)\n\n\*\*Your Answer:\*\*\s*(.*?)(?=\n### Question|\n---|\Z)'
            matches = re.findall(pattern, content, re.DOTALL)

            for match in matches:
                num, topic, question_text, answer = match
                # Clean up the answer (remove placeholder underscores)
                answer = answer.strip()
                if answer == '_____' or answer == '___':
                    answer = ''

                questions.append({
                    'number': int(num),
                    'topic': topic.strip(),
                    'question': question_text.strip(),
                    'answer': answer
                })

    return jsonify({
        'hasQuestions': has_questions,
        'questions': questions,
        'count': len(questions)
    })

@app.route('/api/questions/answer', methods=['POST'])
def answer_questions():
    """Write answers back to Questions_For_You.md"""
    answers = request.json.get('answers', {})

    questions_path = os.path.join(PROJECT_ROOT, 'Questions_For_You.md')

    if not os.path.exists(questions_path):
        return jsonify({'success': False, 'error': 'Questions file not found'})

    with open(questions_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace each answer placeholder with the actual answer
    for num, answer in answers.items():
        # Pattern to find and replace the answer for question N
        pattern = rf'(### Question {num}:.+?\n\*\*Your Answer:\*\*)\s*.*?(?=\n### Question|\n---|\Z)'
        replacement = rf'\1 {answer}'
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    with open(questions_path, 'w', encoding='utf-8') as f:
        f.write(content)

    return jsonify({'success': True})

@app.route('/api/questions/skip', methods=['POST'])
def skip_questions():
    """Mark questions as skipped (let Claude decide)"""
    questions_path = os.path.join(PROJECT_ROOT, 'Questions_For_You.md')

    if not os.path.exists(questions_path):
        return jsonify({'success': False, 'error': 'Questions file not found'})

    with open(questions_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace all answer placeholders with "(Skipped - Claude will decide)"
    pattern = r'(\*\*Your Answer:\*\*)\s*_*'
    content = re.sub(pattern, r'\1 (Skipped - Claude will decide)', content)

    with open(questions_path, 'w', encoding='utf-8') as f:
        f.write(content)

    return jsonify({'success': True})

# ============ Claude Control API ============

@app.route('/api/claude/check')
def check_claude():
    """Check if Claude is installed and logged in"""
    try:
        # Check if claude is installed
        result = subprocess.run(['claude', '--version'],
                              capture_output=True, text=True, timeout=10)
        installed = result.returncode == 0
        version = result.stdout.strip() if installed else None

        # Check login status
        email = None
        if installed:
            result = subprocess.run(['claude', 'config', 'get', 'primaryEmail'],
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0 and result.stdout.strip():
                email = result.stdout.strip()

        return jsonify({
            'installed': installed,
            'version': version,
            'loggedIn': email is not None,
            'email': email
        })
    except FileNotFoundError:
        return jsonify({'installed': False, 'error': 'Claude CLI not found'})
    except subprocess.TimeoutExpired:
        return jsonify({'installed': False, 'error': 'Timeout checking Claude'})
    except Exception as e:
        return jsonify({'installed': False, 'error': str(e)})

@app.route('/api/claude/login', methods=['POST'])
def login_claude():
    """Trigger Claude login in a new console window"""
    try:
        if sys.platform == 'win32':
            subprocess.Popen(['cmd', '/c', 'start', 'cmd', '/k', 'claude login'],
                           cwd=PROJECT_ROOT)
        else:
            subprocess.Popen(['claude', 'login'], cwd=PROJECT_ROOT)
        return jsonify({'success': True, 'message': 'Login window opened'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/claude/generate-plan', methods=['POST'])
def generate_plan():
    """Start Claude to generate a plan"""
    global claude_process

    try:
        if sys.platform == 'win32':
            # Open in new console window so user can see output
            claude_process = subprocess.Popen(
                ['cmd', '/c', 'start', 'cmd', '/k', 'claude -p "Generate a plan"'],
                cwd=PROJECT_ROOT,
                shell=True
            )
        else:
            claude_process = subprocess.Popen(
                ['claude', '-p', 'Generate a plan'],
                cwd=PROJECT_ROOT
            )
        return jsonify({'success': True, 'message': 'Plan generation started'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/claude/execute-plan', methods=['POST'])
def execute_plan():
    """Start Claude to execute the plan"""
    global claude_process

    try:
        if sys.platform == 'win32':
            claude_process = subprocess.Popen(
                ['cmd', '/c', 'start', 'cmd', '/k', 'claude -p "Execute the plan"'],
                cwd=PROJECT_ROOT,
                shell=True
            )
        else:
            claude_process = subprocess.Popen(
                ['claude', '-p', 'Execute the plan'],
                cwd=PROJECT_ROOT
            )
        return jsonify({'success': True, 'message': 'Plan execution started'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/claude/continue', methods=['POST'])
def continue_claude():
    """Continue Claude after answering questions"""
    global claude_process

    try:
        if sys.platform == 'win32':
            claude_process = subprocess.Popen(
                ['cmd', '/c', 'start', 'cmd', '/k', 'claude -p "Continue"'],
                cwd=PROJECT_ROOT,
                shell=True
            )
        else:
            claude_process = subprocess.Popen(
                ['claude', '-p', 'Continue'],
                cwd=PROJECT_ROOT
            )
        return jsonify({'success': True, 'message': 'Continuing execution'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# ============ Cost Report API ============

@app.route('/api/cost')
def get_cost_report():
    """Get cost report data if available"""
    cost_report_path = os.path.join(PROJECT_ROOT, 'output', 'cost_report.md')

    if not os.path.exists(cost_report_path):
        return jsonify({
            'available': False,
            'message': 'No cost report generated yet'
        })

    with open(cost_report_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse key metrics from the report
    metrics = {}

    # Extract total cost
    cost_match = re.search(r'Total Estimated Cost \| \*\*\$([0-9.]+)\*\*', content)
    if cost_match:
        metrics['totalCost'] = float(cost_match.group(1))

    # Extract cache efficiency
    cache_match = re.search(r'Cache Efficiency \| ([0-9.]+)%', content)
    if cache_match:
        metrics['cacheEfficiency'] = float(cache_match.group(1))

    # Extract subagent count
    subagent_match = re.search(r'Subagents Spawned \| (\d+)', content)
    if subagent_match:
        metrics['subagentCount'] = int(subagent_match.group(1))

    # Extract delegation ratio
    delegation_match = re.search(r'Delegation Ratio \| ([0-9.]+)%', content)
    if delegation_match:
        metrics['delegationRatio'] = float(delegation_match.group(1))

    # Extract model used
    model_match = re.search(r'Model Used \| (.+)', content)
    if model_match:
        metrics['model'] = model_match.group(1).strip()

    return jsonify({
        'available': True,
        'metrics': metrics,
        'rawContent': content
    })

@app.route('/api/cost/generate', methods=['POST'])
def generate_cost_report():
    """Generate a new cost report"""
    script_path = os.path.join(PROJECT_ROOT, 'scripts', 'generate_cost_report.py')

    if not os.path.exists(script_path):
        return jsonify({'success': False, 'error': 'Cost report script not found'})

    try:
        result = subprocess.run(
            [sys.executable, script_path, PROJECT_ROOT],
            capture_output=True, text=True, timeout=30
        )

        if result.returncode == 0:
            return jsonify({'success': True, 'message': 'Cost report generated'})
        else:
            return jsonify({'success': False, 'error': result.stderr or 'Failed to generate report'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# ============ Archive API ============

@app.route('/api/archive', methods=['POST'])
def archive_project():
    """Archive current project to timestamped folder"""
    import shutil

    timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
    project_name = request.json.get('projectName', 'project').replace(' ', '_')
    archive_name = f"{timestamp}_{project_name}"
    archive_path = os.path.join(PROJECT_ROOT, 'archive', archive_name)

    os.makedirs(archive_path, exist_ok=True)

    # Files/folders to archive
    items_to_archive = [
        'docs/planning',
        'output',
        'STATUS.md',
        'Questions_For_You.md',
        'config/project-config.json'
    ]

    archived = []
    for item in items_to_archive:
        src = os.path.join(PROJECT_ROOT, item)
        if os.path.exists(src):
            dest = os.path.join(archive_path, item)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if os.path.isdir(src):
                shutil.copytree(src, dest)
            else:
                shutil.copy2(src, dest)
            archived.append(item)

    return jsonify({
        'success': True,
        'archivePath': archive_path,
        'archived': archived
    })

@app.route('/api/reset', methods=['POST'])
def reset_project():
    """Archive current project and reset to fresh state"""
    import shutil

    # First, archive if there's anything to archive
    has_content = any([
        os.path.exists(os.path.join(PROJECT_ROOT, 'docs/planning/task-plan.md')),
        os.path.exists(os.path.join(PROJECT_ROOT, 'output')) and
            any(f for f in os.listdir(os.path.join(PROJECT_ROOT, 'output')) if f != '.gitkeep'),
        os.path.exists(os.path.join(PROJECT_ROOT, 'STATUS.md'))
    ])

    archive_path = None
    if has_content:
        # Archive first
        timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
        project_name = request.json.get('projectName', 'project').replace(' ', '_')
        archive_name = f"{timestamp}_{project_name}"
        archive_path = os.path.join(PROJECT_ROOT, 'archive', archive_name)

        os.makedirs(archive_path, exist_ok=True)

        items_to_archive = [
            'docs/planning',
            'output',
            'STATUS.md',
            'Questions_For_You.md',
            'config/project-config.json'
        ]

        for item in items_to_archive:
            src = os.path.join(PROJECT_ROOT, item)
            if os.path.exists(src):
                dest = os.path.join(archive_path, item)
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                if os.path.isdir(src):
                    shutil.copytree(src, dest)
                else:
                    shutil.copy2(src, dest)

    # Now clear working files
    items_to_clear = [
        'docs/planning/task-plan.md',
        'docs/planning/findings.md',
        'docs/planning/progress.md',
        'docs/planning/references.md',
        'STATUS.md',
        'Questions_For_You.md',
        'config/project-config.json'
    ]

    for item in items_to_clear:
        path = os.path.join(PROJECT_ROOT, item)
        if os.path.exists(path):
            os.remove(path)

    # Clear output folder contents (but keep folder)
    output_dir = os.path.join(PROJECT_ROOT, 'output')
    if os.path.exists(output_dir):
        for item in os.listdir(output_dir):
            if item != '.gitkeep':
                item_path = os.path.join(output_dir, item)
                if os.path.isdir(item_path):
                    shutil.rmtree(item_path)
                else:
                    os.remove(item_path)

    # Create fresh STATUS.md
    fresh_status = """# Project Status

**Last Updated**: Not started

---

## 👉 WHAT TO DO NEXT

**Project not yet started.**

**Your Next Step:** Configure your project and click "Generate Plan"

---

## Quick Status

| Item | Status |
|------|--------|
| Plan Generated | No |
| Current Phase | - |
| Phases Completed | 0 / 0 |

---

## Progress Log

_No progress yet._
"""
    with open(os.path.join(PROJECT_ROOT, 'STATUS.md'), 'w', encoding='utf-8') as f:
        f.write(fresh_status)

    # Create fresh Questions file
    fresh_questions = """# Questions For You

_No questions yet. Claude will write questions here if clarification is needed._
"""
    with open(os.path.join(PROJECT_ROOT, 'Questions_For_You.md'), 'w', encoding='utf-8') as f:
        f.write(fresh_questions)

    return jsonify({
        'success': True,
        'archived': archive_path is not None,
        'archivePath': archive_path,
        'message': 'Project reset. Old files archived.' if archive_path else 'Project reset. No files to archive.'
    })

@app.route('/api/archive/list')
def list_archives():
    """List all archived projects"""
    archive_dir = os.path.join(PROJECT_ROOT, 'archive')
    archives = []

    if os.path.exists(archive_dir):
        for name in sorted(os.listdir(archive_dir), reverse=True):
            if name.startswith('.'):
                continue
            path = os.path.join(archive_dir, name)
            if os.path.isdir(path):
                # Parse timestamp from folder name (format: YYYY-MM-DD_HHMM_ProjectName)
                parts = name.split('_', 2)
                if len(parts) >= 2:
                    archives.append({
                        'name': name,
                        'date': parts[0],
                        'time': parts[1] if len(parts) > 1 else '',
                        'project': parts[2] if len(parts) > 2 else 'Unknown'
                    })

    return jsonify(archives)

@app.route('/api/archive/open')
def open_archive_folder():
    """Open the archive folder in Explorer"""
    archive_dir = os.path.join(PROJECT_ROOT, 'archive')
    os.makedirs(archive_dir, exist_ok=True)

    if sys.platform == 'win32':
        os.startfile(archive_dir)
    elif sys.platform == 'darwin':
        subprocess.run(['open', archive_dir])
    else:
        subprocess.run(['xdg-open', archive_dir])

    return jsonify({'success': True})

@app.route('/api/output/open')
def open_output_folder():
    """Open the output folder in Explorer"""
    output_dir = os.path.join(PROJECT_ROOT, 'output')
    os.makedirs(output_dir, exist_ok=True)

    if sys.platform == 'win32':
        os.startfile(output_dir)
    elif sys.platform == 'darwin':
        subprocess.run(['open', output_dir])
    else:
        subprocess.run(['xdg-open', output_dir])

    return jsonify({'success': True})

# ============ Server Management ============

@app.route('/api/shutdown', methods=['POST'])
def shutdown():
    """Graceful server shutdown"""
    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        # For newer versions of Werkzeug
        os.kill(os.getpid(), signal.SIGINT)
    else:
        func()
    return jsonify({'success': True, 'message': 'Server shutting down...'})

# ============ Main ============

def graceful_shutdown(signum, frame):
    """Handle shutdown signals gracefully"""
    global claude_process
    print("\n\nShutting down gracefully...")

    # Terminate any running Claude process
    if claude_process and claude_process.poll() is None:
        print("  Stopping Claude process...")
        try:
            claude_process.terminate()
            claude_process.wait(timeout=5)
        except Exception:
            claude_process.kill()

    print("  Server stopped.")
    sys.exit(0)

if __name__ == '__main__':
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, graceful_shutdown)
    signal.signal(signal.SIGTERM, graceful_shutdown)

    print("\n" + "="*50)
    print("  Simple Claude Conductor")
    print("="*50)
    print(f"\n  Server running at: http://localhost:8080")
    print(f"  Project root: {PROJECT_ROOT}")
    print("\n  Press Ctrl+C to stop the server.")
    print("="*50 + "\n")

    try:
        app.run(host='127.0.0.1', port=8080, debug=False, threaded=True)
    except KeyboardInterrupt:
        graceful_shutdown(None, None)
