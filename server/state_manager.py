"""
State Manager for Simple Claude Conductor

Manages application state using STATUS.md with YAML frontmatter as the single source of truth.
Implements a state machine with proper transitions and error handling.
"""

import os
import re
import yaml
import threading
from datetime import datetime
from typing import Optional, Dict, Any

try:
    import portalocker
    HAS_PORTALOCKER = True
except ImportError:
    HAS_PORTALOCKER = False


# State machine transition rules
TRANSITIONS = {
    'reset': {
        'configure': 'configured'
    },
    'configured': {
        'generate_plan': 'planning',
        'reset': 'reset'
    },
    'planning': {
        'plan_complete': 'planned',
        'cancel': 'configured',
        'error': 'error'
    },
    'planned': {
        'execute': 'executing',
        'reset': 'reset'
    },
    'executing': {
        'questions_detected': 'questions',
        'phase_complete': 'executing',
        'all_complete': 'complete',
        'cancel': 'planned',
        'error': 'error'
    },
    'questions': {
        'answer': 'executing',
        'skip': 'executing',
        'cancel': 'planned'
    },
    'complete': {
        'reset': 'reset'
    },
    'error': {
        'retry': None,  # Returns to previous_state
        'reset': 'reset'
    }
}

# Valid states
VALID_STATES = {'reset', 'configured', 'planning', 'planned', 'executing', 'questions', 'complete', 'error'}


class StateManager:
    """
    Manages application state via STATUS.md with YAML frontmatter.

    The YAML frontmatter provides structured state for the application while
    keeping human-readable content below for users.

    Thread-safe file operations using portalocker when available.
    """

    DEFAULT_STATE = {
        'state': 'reset',
        'phase': 0,
        'total_phases': 0,
        'phase_name': None,
        'process_id': None,
        'process_start': None,
        'last_updated': None,
        'error': None,
        'previous_state': None,
        'activity': 'Ready to start'
    }

    def __init__(self, project_root: str):
        """
        Initialize StateManager.

        Args:
            project_root: Path to the project root directory
        """
        self.project_root = project_root
        self.status_file = os.path.join(project_root, 'STATUS.md')
        self._lock = threading.RLock()

    def get_state(self) -> Dict[str, Any]:
        """
        Get current state from STATUS.md.

        Returns structured state, falling back to defaults if file is missing
        or malformed.

        Returns:
            Dictionary with state information
        """
        with self._lock:
            state = self.DEFAULT_STATE.copy()

            if not os.path.exists(self.status_file):
                return state

            try:
                content = self._read_file()

                # Try to parse YAML frontmatter
                frontmatter = self._parse_frontmatter(content)
                if frontmatter:
                    state.update(frontmatter)
                else:
                    # Fall back to regex parsing for backward compatibility
                    state = self._parse_legacy_format(content, state)

                # Get file modification time
                mtime = os.path.getmtime(self.status_file)
                state['file_modified'] = datetime.fromtimestamp(mtime).isoformat()

            except Exception as e:
                state['parse_error'] = str(e)

            return state

    def set_state(self, new_state: str, **kwargs) -> Dict[str, Any]:
        """
        Update state directly (for initialization or recovery).

        Args:
            new_state: The state to set
            **kwargs: Additional state fields to update

        Returns:
            Updated state dictionary
        """
        with self._lock:
            if new_state not in VALID_STATES:
                raise ValueError(f"Invalid state: {new_state}. Must be one of {VALID_STATES}")

            state = self.get_state()
            state['state'] = new_state
            state['last_updated'] = datetime.now().isoformat()
            state.update(kwargs)

            self._write_state(state)
            return state

    def transition(self, action: str, **kwargs) -> Dict[str, Any]:
        """
        Perform a state transition.

        Args:
            action: The action triggering the transition
            **kwargs: Additional state fields to update

        Returns:
            Updated state dictionary

        Raises:
            ValueError: If the transition is not valid from the current state
        """
        with self._lock:
            current_state = self.get_state()
            current = current_state['state']

            if current not in TRANSITIONS:
                raise ValueError(f"Unknown current state: {current}")

            valid_actions = TRANSITIONS[current]
            if action not in valid_actions:
                raise ValueError(
                    f"Invalid action '{action}' from state '{current}'. "
                    f"Valid actions: {list(valid_actions.keys())}"
                )

            new_state = valid_actions[action]

            # Special handling for 'retry' action - return to previous state
            if new_state is None and action == 'retry':
                new_state = current_state.get('previous_state', 'reset')

            # Track previous state for error recovery
            if new_state == 'error':
                kwargs['previous_state'] = current

            current_state['state'] = new_state
            current_state['last_updated'] = datetime.now().isoformat()
            current_state.update(kwargs)

            self._write_state(current_state)
            return current_state

    def update_phase(self, phase: int, total: int, name: Optional[str] = None) -> Dict[str, Any]:
        """
        Update phase progress without changing state.

        Args:
            phase: Current phase number
            total: Total number of phases
            name: Optional phase name

        Returns:
            Updated state dictionary
        """
        with self._lock:
            state = self.get_state()
            state['phase'] = phase
            state['total_phases'] = total
            if name:
                state['phase_name'] = name
            state['last_updated'] = datetime.now().isoformat()

            self._write_state(state)
            return state

    def set_activity(self, activity: str) -> Dict[str, Any]:
        """
        Update the activity message.

        Args:
            activity: Human-readable activity description

        Returns:
            Updated state dictionary
        """
        with self._lock:
            state = self.get_state()
            state['activity'] = activity
            state['last_updated'] = datetime.now().isoformat()

            self._write_state(state)
            return state

    def set_error(self, error_message: str) -> Dict[str, Any]:
        """
        Transition to error state with message.

        Args:
            error_message: Description of the error

        Returns:
            Updated state dictionary
        """
        return self.transition('error', error=error_message)

    def set_process(self, pid: Optional[int]) -> Dict[str, Any]:
        """
        Update the running process information.

        Args:
            pid: Process ID or None if no process running

        Returns:
            Updated state dictionary
        """
        with self._lock:
            state = self.get_state()
            state['process_id'] = pid
            if pid:
                state['process_start'] = datetime.now().isoformat()
            else:
                state['process_start'] = None
            state['last_updated'] = datetime.now().isoformat()

            self._write_state(state)
            return state

    def _read_file(self) -> str:
        """Read STATUS.md with optional file locking."""
        if HAS_PORTALOCKER:
            with portalocker.Lock(self.status_file, 'r', encoding='utf-8', timeout=5) as f:
                return f.read()
        else:
            with open(self.status_file, 'r', encoding='utf-8') as f:
                return f.read()

    def _write_file(self, content: str) -> None:
        """Write STATUS.md with optional file locking."""
        if HAS_PORTALOCKER:
            with portalocker.Lock(self.status_file, 'w', encoding='utf-8', timeout=5) as f:
                f.write(content)
        else:
            with open(self.status_file, 'w', encoding='utf-8') as f:
                f.write(content)

    def _parse_frontmatter(self, content: str) -> Optional[Dict[str, Any]]:
        """
        Parse YAML frontmatter from STATUS.md.

        Args:
            content: Full file content

        Returns:
            Dictionary of parsed YAML or None if no valid frontmatter
        """
        match = re.match(r'^---\n(.+?)\n---', content, re.DOTALL)
        if not match:
            return None

        try:
            parsed = yaml.safe_load(match.group(1))
            if isinstance(parsed, dict):
                return parsed
        except yaml.YAMLError:
            pass

        return None

    def _parse_legacy_format(self, content: str, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse STATUS.md using regex for backward compatibility.

        Args:
            content: Full file content
            state: State dictionary to update

        Returns:
            Updated state dictionary
        """
        # Parse phase info (e.g., "Phase 2 of 5")
        phase_match = re.search(r'Phase (\d+) of (\d+)', content)
        if phase_match:
            state['phase'] = int(phase_match.group(1))
            state['total_phases'] = int(phase_match.group(2))

        # Parse phase name
        phase_name_match = re.search(r'Current Phase.*?Phase \d+ of \d+:\s*(.+)', content)
        if phase_name_match:
            state['phase_name'] = phase_name_match.group(1).strip()

        # Parse last updated
        updated_match = re.search(r'\*\*Last Updated\*\*:\s*(.+)', content)
        if updated_match:
            state['last_updated'] = updated_match.group(1).strip()

        # Extract activity from "WHAT TO DO NEXT" section
        next_match = re.search(r'## 👉 WHAT TO DO NEXT\s*\n\n(.+?)(?=\n---|\n##|$)', content, re.DOTALL)
        if next_match:
            state['activity'] = next_match.group(1).strip()

        # Detect state from content
        if 'Phases Completed' in content:
            completed_match = re.search(r'Phases Completed\s*\|\s*(\d+)\s*/\s*(\d+)', content)
            if completed_match:
                completed = int(completed_match.group(1))
                total = int(completed_match.group(2))
                if completed == total and total > 0:
                    state['state'] = 'complete'
                elif 'Questions_For_You.md' in state.get('activity', ''):
                    state['state'] = 'questions'
                elif 'Executing' in content or 'In Progress' in content:
                    state['state'] = 'executing'
                elif 'Plan Generated | Yes' in content or state['total_phases'] > 0:
                    state['state'] = 'planned'
                else:
                    state['state'] = 'reset'

        return state

    def _write_state(self, state: Dict[str, Any]) -> None:
        """
        Write state to STATUS.md with YAML frontmatter.

        Args:
            state: State dictionary to write
        """
        # Build YAML frontmatter
        frontmatter_fields = [
            'state', 'phase', 'total_phases', 'phase_name',
            'process_id', 'process_start', 'last_updated',
            'error', 'previous_state', 'activity'
        ]
        frontmatter = {k: state.get(k) for k in frontmatter_fields}

        yaml_content = yaml.dump(frontmatter, default_flow_style=False, allow_unicode=True)

        # Determine human-readable status elements
        last_updated = datetime.now().strftime('%Y-%m-%d %H:%M')
        phase_str = f"Phase {state.get('phase', 0)} of {state.get('total_phases', 0)}"
        if state.get('phase_name'):
            phase_str += f": {state['phase_name']}"

        activity = state.get('activity', 'Ready to start')
        current_state = state.get('state', 'reset')

        # Calculate completed phases
        completed = state.get('phase', 0)
        if current_state == 'complete':
            completed = state.get('total_phases', 0)
        elif current_state in ('reset', 'configured', 'planning'):
            completed = 0
        else:
            completed = max(0, state.get('phase', 1) - 1)

        # Build STATUS.md content
        content = f"""---
{yaml_content.strip()}
---
# Project Status: Conductor UI Rebuild

**Last Updated**: {last_updated}

---

## 👉 WHAT TO DO NEXT

{activity}

---

## Quick Status

| Item | Status |
|------|--------|
| Plan Generated | {'Yes' if state.get('total_phases', 0) > 0 else 'No'} |
| Current Phase | {phase_str if state.get('total_phases', 0) > 0 else '-'} |
| Phases Completed | {completed} / {state.get('total_phases', 0)} |

---

## Progress Log

_State managed by StateManager_
"""

        self._write_file(content)


# Singleton instance (created when module is imported with project root)
_state_manager: Optional[StateManager] = None


def get_state_manager(project_root: Optional[str] = None) -> StateManager:
    """
    Get or create the StateManager singleton.

    Args:
        project_root: Path to project root (required on first call)

    Returns:
        StateManager instance
    """
    global _state_manager

    if _state_manager is None:
        if project_root is None:
            raise ValueError("project_root required for first initialization")
        _state_manager = StateManager(project_root)

    return _state_manager
