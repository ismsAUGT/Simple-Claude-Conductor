"""
Process Manager for Simple Claude Conductor

Manages Claude subprocess with proper PID tracking and output capture.
Uses direct subprocess (no cmd indirection) so PIDs can actually be tracked.
"""

import subprocess
import sys
import threading
import queue
import os
from datetime import datetime
from typing import Optional, List, Callable


class ProcessManager:
    """
    Manages Claude subprocess with proper tracking.

    Key features:
    - Direct subprocess (no cmd /c start indirection)
    - Output capture for logging
    - Proper Windows console handling
    - Timeout detection
    - Crash detection
    - Thread-safe operations
    """

    def __init__(self):
        """Initialize ProcessManager."""
        self.process: Optional[subprocess.Popen] = None
        self.output_queue: queue.Queue = queue.Queue()
        self.output_thread: Optional[threading.Thread] = None
        self.start_time: Optional[datetime] = None
        self._lock = threading.RLock()
        self._on_exit_callback: Optional[Callable[[int], None]] = None

    def start_claude(
        self,
        prompt: str,
        working_dir: str,
        new_console: bool = True
    ) -> int:
        """
        Start Claude with given prompt.

        Args:
            prompt: Command/prompt to send to Claude
            working_dir: Project root directory
            new_console: Whether to open a new console window (Windows)

        Returns:
            Process ID

        Raises:
            RuntimeError: If Claude is already running
        """
        with self._lock:
            if self.is_running():
                raise RuntimeError("Claude is already running")

            # Clear old output
            while not self.output_queue.empty():
                try:
                    self.output_queue.get_nowait()
                except queue.Empty:
                    break

            # Build command
            cmd = ['claude', '-p', prompt]

            # Platform-specific subprocess creation
            kwargs = {
                'cwd': working_dir,
                'stdout': subprocess.PIPE,
                'stderr': subprocess.STDOUT,
                'text': True,
                'bufsize': 1,  # Line buffered
            }

            if sys.platform == 'win32':
                if new_console:
                    # CREATE_NEW_CONSOLE: Claude gets its own console window
                    # This lets the user see Claude's output directly
                    # AND we can still track the PID properly
                    kwargs['creationflags'] = subprocess.CREATE_NEW_CONSOLE
                    # When using CREATE_NEW_CONSOLE, we can't capture stdout
                    # so remove those settings
                    del kwargs['stdout']
                    del kwargs['stderr']
                    del kwargs['text']
                    del kwargs['bufsize']

            try:
                self.process = subprocess.Popen(cmd, **kwargs)
                self.start_time = datetime.now()
            except FileNotFoundError:
                raise RuntimeError(
                    "Claude CLI not found. Please ensure 'claude' is installed and in PATH."
                )

            # Start output reader thread (only if we're capturing output)
            if 'stdout' in kwargs:
                self.output_thread = threading.Thread(
                    target=self._read_output,
                    daemon=True
                )
                self.output_thread.start()

            # Start exit monitor thread
            monitor_thread = threading.Thread(
                target=self._monitor_exit,
                daemon=True
            )
            monitor_thread.start()

            return self.process.pid

    def _read_output(self) -> None:
        """Read subprocess output in background thread."""
        try:
            if self.process and self.process.stdout:
                for line in self.process.stdout:
                    self.output_queue.put(line.rstrip())
        except Exception:
            pass

    def _monitor_exit(self) -> None:
        """Monitor for process exit and trigger callback."""
        if self.process is None:
            return

        # Wait for process to complete
        return_code = self.process.wait()

        # Trigger callback if set
        if self._on_exit_callback:
            try:
                self._on_exit_callback(return_code)
            except Exception:
                pass

    def on_exit(self, callback: Callable[[int], None]) -> None:
        """
        Set callback to be called when process exits.

        Args:
            callback: Function taking return code as argument
        """
        self._on_exit_callback = callback

    def is_running(self) -> bool:
        """
        Check if Claude subprocess is actually running.

        Returns:
            True if process is running, False otherwise
        """
        if self.process is None:
            return False

        # poll() returns None if still running, return code if finished
        return self.process.poll() is None

    def get_pid(self) -> Optional[int]:
        """
        Get process ID if running.

        Returns:
            PID or None if not running
        """
        if self.process is None or not self.is_running():
            return None
        return self.process.pid

    def get_return_code(self) -> Optional[int]:
        """
        Get process return code.

        Returns:
            Return code if process finished, None if still running
        """
        if self.process is None:
            return None
        return self.process.poll()

    def get_recent_output(self, max_lines: int = 50) -> List[str]:
        """
        Get recent output lines (non-blocking).

        Args:
            max_lines: Maximum number of lines to return

        Returns:
            List of output lines
        """
        lines = []
        while not self.output_queue.empty() and len(lines) < max_lines:
            try:
                lines.append(self.output_queue.get_nowait())
            except queue.Empty:
                break
        return lines

    def get_runtime_seconds(self) -> Optional[float]:
        """
        Get how long the process has been running.

        Returns:
            Runtime in seconds or None if not started
        """
        if self.start_time is None:
            return None
        return (datetime.now() - self.start_time).total_seconds()

    def stop(self, timeout: float = 10.0) -> bool:
        """
        Stop Claude gracefully.

        Args:
            timeout: Seconds to wait before force kill

        Returns:
            True if stopped cleanly, False if force killed
        """
        if not self.is_running():
            return True

        with self._lock:
            # Try graceful termination first
            self.process.terminate()

            try:
                self.process.wait(timeout=timeout)
                return True
            except subprocess.TimeoutExpired:
                # Force kill
                self.process.kill()
                self.process.wait()
                return False

    def reset(self) -> None:
        """
        Reset process manager state.

        Stops any running process and clears state.
        """
        self.stop()
        with self._lock:
            self.process = None
            self.start_time = None
            self._on_exit_callback = None
            # Clear output queue
            while not self.output_queue.empty():
                try:
                    self.output_queue.get_nowait()
                except queue.Empty:
                    break


class TimeoutMonitor:
    """
    Monitor for stuck/hung processes.

    Detects when Claude hasn't updated STATUS.md for too long.
    """

    # Thresholds in seconds
    STALL_THRESHOLD = 5 * 60   # 5 minutes without update = stalled
    HARD_TIMEOUT = 30 * 60    # 30 minutes total = timeout

    def __init__(self, status_file: str):
        """
        Initialize timeout monitor.

        Args:
            status_file: Path to STATUS.md
        """
        self.status_file = status_file
        self.process_start: Optional[datetime] = None

    def start(self) -> None:
        """Mark process start time."""
        self.process_start = datetime.now()

    def stop(self) -> None:
        """Clear process start time."""
        self.process_start = None

    def check(self) -> dict:
        """
        Check for timeout conditions.

        Returns:
            Dictionary with:
                - stalled: True if no updates for STALL_THRESHOLD
                - timed_out: True if running longer than HARD_TIMEOUT
                - last_update: Last modification time of STATUS.md
                - runtime: How long process has been running
        """
        now = datetime.now()

        # Get STATUS.md modification time
        last_update = None
        try:
            if os.path.exists(self.status_file):
                mtime = os.path.getmtime(self.status_file)
                last_update = datetime.fromtimestamp(mtime)
        except OSError:
            pass

        # Calculate runtime
        runtime = None
        if self.process_start:
            runtime = (now - self.process_start).total_seconds()

        # Check conditions
        stalled = False
        if last_update:
            seconds_since_update = (now - last_update).total_seconds()
            stalled = seconds_since_update > self.STALL_THRESHOLD

        timed_out = False
        if runtime:
            timed_out = runtime > self.HARD_TIMEOUT

        return {
            'stalled': stalled,
            'timed_out': timed_out,
            'last_update': last_update.isoformat() if last_update else None,
            'runtime': runtime
        }


# Singleton instance
_process_manager: Optional[ProcessManager] = None


def get_process_manager() -> ProcessManager:
    """
    Get or create the ProcessManager singleton.

    Returns:
        ProcessManager instance
    """
    global _process_manager

    if _process_manager is None:
        _process_manager = ProcessManager()

    return _process_manager
