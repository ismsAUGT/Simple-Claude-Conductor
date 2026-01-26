"""
Simple Claude Conductor - Web UI Server

A Flask server that provides a web interface for managing Claude Code projects.
Designed for non-technical users who need a GUI instead of terminal commands.

v2.0 - Rebuilt with StateManager, ProcessManager, and SSE support.
"""

from flask import Flask, render_template, jsonify, request, Response
import subprocess
import os
import sys
import json
import re
import signal
import shutil
import time
from datetime import datetime

# Add the project root to path for imports
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)
os.chdir(PROJECT_ROOT)

# Import managers (after adding project root to path)
from server.state_manager import get_state_manager, StateManager
from server.process_manager import get_process_manager, ProcessManager, TimeoutMonitor

app = Flask(__name__,
            template_folder='templates',
            static_folder='static')

# Initialize managers
state_manager = get_state_manager(PROJECT_ROOT)
process_manager = get_process_manager()
timeout_monitor = TimeoutMonitor(os.path.join(PROJECT_ROOT, 'STATUS.md'))


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


# ============ Server-Sent Events ============

@app.route('/api/events')
def events():
    """
    Server-Sent Events endpoint for real-time state updates.

    Sends state updates every second for reactive UI updates.
    """
    def generate():
        while True:
            try:
                # Get current state
                state = state_manager.get_state()

                # Add process running status
                state['claudeRunning'] = process_manager.is_running()
                state['processPid'] = process_manager.get_pid()

                # Add timeout info
                timeout_info = timeout_monitor.check()
                state['stalled'] = timeout_info.get('stalled', False)
                state['timedOut'] = timeout_info.get('timed_out', False)

                # Send state as SSE event
                yield f"data: {json.dumps(state)}\n\n"

            except Exception as e:
                # Send error state
                yield f"data: {json.dumps({'error': str(e)})}\n\n"

            time.sleep(1)  # Update every second

    return Response(
        generate(),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'X-Accel-Buffering': 'no'  # Disable nginx buffering
        }
    )


# ============ State API ============

@app.route('/api/state')
def get_state():
    """Get current application state from StateManager"""
    state = state_manager.get_state()

    # Add process status
    state['claudeRunning'] = process_manager.is_running()
    state['processPid'] = process_manager.get_pid()

    # Add timeout info
    timeout_info = timeout_monitor.check()
    state['stalled'] = timeout_info.get('stalled', False)
    state['timedOut'] = timeout_info.get('timed_out', False)

    return jsonify(state)


@app.route('/api/status')
def get_status():
    """
    Read STATUS.md and parse current state.

    Backward-compatible endpoint that also reads raw content.
    """
    state = state_manager.get_state()

    # Add raw content for backward compatibility
    status_path = os.path.join(PROJECT_ROOT, 'STATUS.md')
    if os.path.exists(status_path):
        with open(status_path, 'r', encoding='utf-8') as f:
            state['raw'] = f.read()
    else:
        state['raw'] = ''

    # Map to old field names for backward compatibility
    state['total'] = state.get('total_phases', 0)
    state['phaseName'] = state.get('phase_name')
    state['lastUpdated'] = state.get('last_updated')
    state['planGenerated'] = state.get('total_phases', 0) > 0
    state['claudeRunning'] = process_manager.is_running()

    return jsonify(state)


# ============ Helper Functions ============

def detect_plan_phases():
    """
    Detect phases from task-plan.md.

    Returns tuple of (phase_count, phase_names) by parsing the markdown.
    """
    task_plan_path = os.path.join(PROJECT_ROOT, 'docs', 'planning', 'task-plan.md')

    if not os.path.exists(task_plan_path):
        return 0, []

    try:
        with open(task_plan_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for phase headers like "### Phase 1:" or "### Phase 1 -"
        phase_pattern = r'###\s+Phase\s+(\d+)[:\s-]+(.+?)(?=\n|$)'
        matches = re.findall(phase_pattern, content)

        if matches:
            phase_count = len(matches)
            phase_names = [name.strip() for _, name in matches]
            return phase_count, phase_names

        return 0, []
    except Exception:
        return 0, []


def detect_plan_completion():
    """
    Check if the plan has been completed by looking at STATUS.md and task-plan.md.
    """
    # Check STATUS.md for completion indicators
    status_path = os.path.join(PROJECT_ROOT, 'STATUS.md')
    if os.path.exists(status_path):
        with open(status_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for completion indicators
        if 'Phases Completed' in content:
            match = re.search(r'Phases Completed\s*\|\s*(\d+)\s*/\s*(\d+)', content)
            if match:
                completed = int(match.group(1))
                total = int(match.group(2))
                if completed >= total and total > 0:
                    return True

        # Also check for "Complete" in status
        if 'Current Phase | Complete' in content or 'Phase | Complete' in content:
            return True

    return False


# ============ Action API ============

@app.route('/api/actions/generate-plan', methods=['POST'])
def action_generate_plan():
    """Start Claude to generate a plan"""
    try:
        if process_manager.is_running():
            return jsonify({
                'success': False,
                'error': 'Claude is already running'
            }), 400

        # Update state to planning
        state_manager.set_state('planning',
                               activity='Generating plan... A terminal window will appear - you can ignore it.')
        timeout_monitor.start()

        # Start Claude process
        pid = process_manager.start_claude('Generate a plan', PROJECT_ROOT)
        state_manager.set_process(pid)

        # Set up exit callback to detect completion
        def on_exit(return_code):
            if return_code == 0:
                # Check if plan was generated by looking at task-plan.md
                phase_count, phase_names = detect_plan_phases()

                if phase_count > 0:
                    # Plan was generated successfully
                    state_manager.set_state('planned',
                                           phase=1,
                                           total_phases=phase_count,
                                           phase_name=phase_names[0] if phase_names else None,
                                           activity=f'Plan generated with {phase_count} phase(s). Ready to execute!')
                else:
                    state_manager.set_state('configured',
                                           activity='Plan generation completed but no phases found in task-plan.md')
            else:
                state_manager.set_error(f'Claude exited with code {return_code}')

            state_manager.set_process(None)
            timeout_monitor.stop()

        process_manager.on_exit(on_exit)

        return jsonify({
            'success': True,
            'message': 'Plan generation started',
            'pid': pid
        })
    except Exception as e:
        state_manager.set_error(str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/actions/execute', methods=['POST'])
def action_execute_plan():
    """Start Claude to execute the plan"""
    try:
        if process_manager.is_running():
            return jsonify({
                'success': False,
                'error': 'Claude is already running'
            }), 400

        # Update state to executing
        state_manager.set_state('executing',
                               activity='Executing plan... A terminal window will appear - you can ignore it.')
        timeout_monitor.start()

        # Start Claude process
        pid = process_manager.start_claude('Execute the plan', PROJECT_ROOT)
        state_manager.set_process(pid)

        # Set up exit callback
        def on_exit(return_code):
            if return_code == 0:
                # Check if execution completed
                if detect_plan_completion():
                    state_manager.set_state('complete',
                                           activity='Project complete! Click "Open Output" to review your deliverables.')
                else:
                    # Execution finished but might need to continue
                    state_manager.set_state('planned',
                                           activity='Execution finished. Check status for results.')
            else:
                state_manager.set_error(f'Claude exited with code {return_code}')

            state_manager.set_process(None)
            timeout_monitor.stop()

        process_manager.on_exit(on_exit)

        return jsonify({
            'success': True,
            'message': 'Plan execution started',
            'pid': pid
        })
    except Exception as e:
        state_manager.set_error(str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/actions/continue', methods=['POST'])
def action_continue():
    """Continue Claude after answering questions"""
    try:
        if process_manager.is_running():
            return jsonify({
                'success': False,
                'error': 'Claude is already running'
            }), 400

        # Update state back to executing
        state_manager.set_state('executing', activity='Continuing execution...')
        timeout_monitor.start()

        # Start Claude process
        pid = process_manager.start_claude('Continue', PROJECT_ROOT)
        state_manager.set_process(pid)

        # Set up exit callback
        def on_exit(return_code):
            if return_code == 0:
                state = state_manager.get_state()
                if state.get('phase', 0) >= state.get('total_phases', 0):
                    state_manager.set_state('complete', activity='Execution complete!')
            else:
                state_manager.set_error(f'Claude exited with code {return_code}')

            state_manager.set_process(None)
            timeout_monitor.stop()

        process_manager.on_exit(on_exit)

        return jsonify({
            'success': True,
            'message': 'Continuing execution',
            'pid': pid
        })
    except Exception as e:
        state_manager.set_error(str(e))
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/actions/cancel', methods=['POST'])
def action_cancel():
    """Cancel current operation"""
    try:
        was_running = process_manager.is_running()

        # Stop the process
        stopped_cleanly = process_manager.stop(timeout=10.0)

        # Get current state to determine where to go back
        state = state_manager.get_state()
        current = state.get('state', 'reset')

        # Transition based on current state
        if current == 'planning':
            state_manager.set_state('configured',
                                   activity='Plan generation cancelled.')
        elif current in ('executing', 'questions'):
            state_manager.set_state('planned',
                                   activity='Execution cancelled. You can restart when ready.')

        state_manager.set_process(None)
        timeout_monitor.stop()

        return jsonify({
            'success': True,
            'wasRunning': was_running,
            'stoppedCleanly': stopped_cleanly,
            'message': 'Operation cancelled'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/actions/retry', methods=['POST'])
def action_retry():
    """Retry after error - return to previous state"""
    try:
        state = state_manager.get_state()

        if state.get('state') != 'error':
            return jsonify({
                'success': False,
                'error': 'Can only retry from error state'
            }), 400

        # Clear error and return to previous state
        previous = state.get('previous_state', 'reset')
        state_manager.set_state(previous, error=None,
                               activity=f'Retrying from {previous} state...')

        return jsonify({
            'success': True,
            'previousState': previous,
            'message': f'Returned to {previous} state'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/actions/reset', methods=['POST'])
def action_reset():
    """Reset to initial state"""
    try:
        # Stop any running process
        process_manager.stop()
        timeout_monitor.stop()

        # Reset state
        state_manager.set_state('reset',
                               phase=0,
                               total_phases=0,
                               phase_name=None,
                               error=None,
                               activity='Ready to start')

        return jsonify({
            'success': True,
            'message': 'State reset to initial'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


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

    # Transition to configured state if currently in reset
    state = state_manager.get_state()
    if state.get('state') == 'reset':
        state_manager.set_state('configured', activity='Project configured. Ready to generate plan.')

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
        feedback_items.append('Too short: Try adding more detail about what you want to build')
        quality = 'needs_work'
    elif word_count < 30:
        feedback_items.append('Consider adding more specific details about features and requirements')

    # Check for specificity indicators
    specificity_words = ['should', 'must', 'need', 'want', 'require', 'include', 'feature', 'function', 'button', 'page', 'form', 'api', 'database', 'user']
    has_specificity = any(word in description.lower() for word in specificity_words)
    if not has_specificity:
        feedback_items.append('Be more specific: Mention specific features, functions, or requirements')
        quality = 'needs_work'

    # Check for output format hints
    output_words = ['file', 'output', 'generate', 'create', 'build', 'make', 'produce', 'return', 'display', 'show']
    has_output_hint = any(word in description.lower() for word in output_words)
    if not has_output_hint:
        feedback_items.append('Consider specifying what the expected output should look like')

    # Check for technology mentions
    tech_words = ['python', 'javascript', 'html', 'css', 'react', 'flask', 'node', 'api', 'json', 'sql', 'database']
    has_tech = any(word in description.lower() for word in tech_words)
    if has_tech:
        feedback_items.append('Good: You mentioned specific technologies')

    return jsonify({
        'success': True,
        'quality': quality,
        'feedback': feedback_items
    })


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


@app.route('/api/references/upload', methods=['POST'])
def upload_references():
    """Handle file uploads to reference folder"""
    ref_dir = os.path.join(PROJECT_ROOT, 'File_References_For_Your_Project')
    os.makedirs(ref_dir, exist_ok=True)

    if 'files' not in request.files:
        return jsonify({'success': False, 'error': 'No files provided'}), 400

    files = request.files.getlist('files')
    uploaded = []

    for file in files:
        if file.filename:
            # Sanitize filename
            filename = os.path.basename(file.filename)
            filepath = os.path.join(ref_dir, filename)

            # Save file
            file.save(filepath)
            uploaded.append(filename)

    return jsonify({'success': True, 'files': uploaded})


@app.route('/api/references/archive', methods=['POST'])
def archive_references():
    """Archive all reference files to timestamped folder"""
    ref_dir = os.path.join(PROJECT_ROOT, 'File_References_For_Your_Project')

    if not os.path.exists(ref_dir):
        return jsonify({'success': False, 'error': 'Reference folder does not exist'})

    # Get list of files (excluding hidden files)
    files = [f for f in os.listdir(ref_dir) if not f.startswith('.')]
    if not files:
        return jsonify({'success': False, 'error': 'No files to archive'})

    # Create archive folder
    timestamp = datetime.now().strftime('%Y-%m-%d_%H%M')
    archive_name = f"{timestamp}_reference_files"
    archive_path = os.path.join(PROJECT_ROOT, 'archive', archive_name)
    os.makedirs(archive_path, exist_ok=True)

    # Move files to archive
    archived = []
    for f in files:
        src = os.path.join(ref_dir, f)
        dest = os.path.join(archive_path, f)
        if os.path.isdir(src):
            shutil.move(src, dest)
        else:
            shutil.move(src, dest)
        archived.append(f)

    return jsonify({
        'success': True,
        'archived': archived,
        'archivePath': archive_path
    })


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
            pattern = r'### Question (\d+):\s*(.+?)\n(.+?)\n\n\*\*Your Answer:\*\*\s*(.*?)(?=\n### Question|\n---|\Z)'
            matches = re.findall(pattern, content, re.DOTALL)

            for match in matches:
                num, topic, question_text, answer = match
                answer = answer.strip()
                if answer == '_____' or answer == '___':
                    answer = ''

                questions.append({
                    'number': int(num),
                    'topic': topic.strip(),
                    'question': question_text.strip(),
                    'answer': answer
                })

    # Update state if questions detected
    if has_questions and not any(q.get('answer') for q in questions):
        state = state_manager.get_state()
        if state.get('state') == 'executing':
            state_manager.set_state('questions', activity='Claude has questions for you')

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
    """Check if Claude is installed and working"""
    try:
        # Check if claude is installed using shutil.which (cross-platform)
        claude_path = shutil.which('claude')
        installed = claude_path is not None

        version = None
        logged_in = False

        if installed:
            # Try to get version - if this works, Claude is installed and usable
            try:
                result = subprocess.run(['claude', '--version'],
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    version = result.stdout.strip()
                    # If version command works, Claude is functional
                    # (Claude requires login to work at all)
                    logged_in = True
            except Exception:
                pass

        return jsonify({
            'installed': installed,
            'version': version,
            'loggedIn': logged_in,
            'email': 'Logged in' if logged_in else None
        })
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


@app.route('/api/plan/open')
def open_plan():
    """Open task-plan.md in default editor/viewer"""
    plan_path = os.path.join(PROJECT_ROOT, 'docs', 'planning', 'task-plan.md')

    if not os.path.exists(plan_path):
        return jsonify({'success': False, 'error': 'Plan file not found'})

    try:
        if sys.platform == 'win32':
            os.startfile(plan_path)
        elif sys.platform == 'darwin':
            subprocess.run(['open', plan_path])
        else:
            subprocess.run(['xdg-open', plan_path])

        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


# Legacy endpoints for backward compatibility
@app.route('/api/claude/generate-plan', methods=['POST'])
def generate_plan():
    """Legacy: Start Claude to generate a plan"""
    return action_generate_plan()


@app.route('/api/claude/execute-plan', methods=['POST'])
def execute_plan():
    """Legacy: Start Claude to execute the plan"""
    return action_execute_plan()


@app.route('/api/claude/continue', methods=['POST'])
def continue_claude():
    """Legacy: Continue Claude after answering questions"""
    return action_continue()


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

    cost_match = re.search(r'Total Estimated Cost \| \*\*\$([0-9.]+)\*\*', content)
    if cost_match:
        metrics['totalCost'] = float(cost_match.group(1))

    cache_match = re.search(r'Cache Efficiency \| ([0-9.]+)%', content)
    if cache_match:
        metrics['cacheEfficiency'] = float(cache_match.group(1))

    subagent_match = re.search(r'Subagents Spawned \| (\d+)', content)
    if subagent_match:
        metrics['subagentCount'] = int(subagent_match.group(1))

    delegation_match = re.search(r'Delegation Ratio \| ([0-9.]+)%', content)
    if delegation_match:
        metrics['delegationRatio'] = float(delegation_match.group(1))

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
    # First, archive if there's anything to archive
    has_content = any([
        os.path.exists(os.path.join(PROJECT_ROOT, 'docs/planning/task-plan.md')),
        os.path.exists(os.path.join(PROJECT_ROOT, 'output')) and
            any(f for f in os.listdir(os.path.join(PROJECT_ROOT, 'output')) if f != '.gitkeep'),
        os.path.exists(os.path.join(PROJECT_ROOT, 'STATUS.md'))
    ])

    archive_path = None
    if has_content:
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

    # Clear working files
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

    # Clear output folder contents
    output_dir = os.path.join(PROJECT_ROOT, 'output')
    if os.path.exists(output_dir):
        for item in os.listdir(output_dir):
            if item != '.gitkeep':
                item_path = os.path.join(output_dir, item)
                if os.path.isdir(item_path):
                    shutil.rmtree(item_path)
                else:
                    os.remove(item_path)

    # Reset state manager
    state_manager.set_state('reset',
                           phase=0,
                           total_phases=0,
                           phase_name=None,
                           error=None,
                           activity='Project reset. Configure to start new project.')

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


@app.route('/api/system/status')
def system_status():
    """Get system status (same as claude/check but different path)"""
    return check_claude()


@app.route('/api/system/open-output', methods=['POST'])
def system_open_output():
    """Open output folder (API spec path)"""
    return open_output_folder()


# ============ Server Management ============

@app.route('/api/shutdown', methods=['POST'])
def shutdown():
    """Graceful server shutdown"""
    # Stop any running Claude process
    process_manager.stop()

    func = request.environ.get('werkzeug.server.shutdown')
    if func is None:
        os.kill(os.getpid(), signal.SIGINT)
    else:
        func()
    return jsonify({'success': True, 'message': 'Server shutting down...'})


# ============ Main ============

def graceful_shutdown(signum, frame):
    """Handle shutdown signals gracefully"""
    print("\n\nShutting down gracefully...")

    # Terminate any running Claude process
    if process_manager.is_running():
        print("  Stopping Claude process...")
        process_manager.stop(timeout=5)

    print("  Server stopped.")
    sys.exit(0)


if __name__ == '__main__':
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, graceful_shutdown)
    signal.signal(signal.SIGTERM, graceful_shutdown)

    print("\n" + "="*50)
    print("  Simple Claude Conductor v2.0")
    print("="*50)
    print(f"\n  Server running at: http://localhost:8080")
    print(f"  Project root: {PROJECT_ROOT}")
    print("\n  Features:")
    print("    - SSE endpoint: /api/events")
    print("    - State machine with proper transitions")
    print("    - Process management with PID tracking")
    print("\n  Press Ctrl+C to stop the server.")
    print("="*50 + "\n")

    try:
        app.run(host='127.0.0.1', port=8080, debug=False, threaded=True)
    except KeyboardInterrupt:
        graceful_shutdown(None, None)
