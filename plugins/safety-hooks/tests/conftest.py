"""Pytest configuration and fixtures for safety-hooks tests."""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Add hooks directory to Python path for imports
HOOKS_DIR = Path(__file__).parent.parent / "hooks"
if str(HOOKS_DIR) not in sys.path:
    sys.path.insert(0, str(HOOKS_DIR))


@pytest.fixture
def mock_config():
    """Return a mock SafetyHooksConfig with customizable values."""

    def _config(**kwargs):
        from config import SafetyHooksConfig

        defaults = {
            "rm_block_enabled": True,
            "git_add_block_enabled": True,
            "git_checkout_block_enabled": True,
            "git_commit_ask_enabled": True,
            "env_protection_enabled": True,
            "file_length_limit_enabled": True,
            "file_max_lines": 10000,
            "file_extensions": None,
            "rm_trash_dir": "TRASH",
            "rm_require_log": True,
            "rm_log_file": "TRASH-FILES.md",
            "git_allow_wildcards": False,
            "git_allow_dot_add": False,
            "git_allow_all_flag": False,
            "git_checkout_force_protection": True,
            "git_checkout_dot_protection": True,
        }
        defaults.update(kwargs)
        return SafetyHooksConfig(**defaults)

    return _config


@pytest.fixture
def mock_get_config(mock_config):
    """Mock get_config() to return a test config."""

    def _get_config(**kwargs):
        cfg = mock_config(**kwargs)

        with patch("config.get_config", return_value=cfg):
            yield cfg

    return _get_config


@pytest.fixture
def sample_hook_input():
    """Return a sample hook input dict."""

    def _input(tool_name: str = "Bash", tool_input: dict | None = None):
        return {
            "session_id": "test-session-123",
            "transcript_path": "/tmp/transcript.txt",
            "cwd": "/test/project",
            "permission_mode": "ask",
            "hook_event_name": "PreToolUse",
            "tool_name": tool_name,
            "tool_input": tool_input or {},
        }

    return _input


@pytest.fixture
def mock_git_subprocess():
    """Mock subprocess.run for git commands.

    Returns a MagicMock that can be configured to return different results.
    """
    mock_result = MagicMock()
    mock_result.stdout = ""
    mock_result.stderr = ""
    mock_result.returncode = 0

    with patch("subprocess.run", return_value=mock_result) as mock:
        yield mock


@pytest.fixture
def mock_git_status_clean(mock_git_subprocess):
    """Mock git status returning no changes."""
    mock_result = MagicMock()
    mock_result.stdout = ""
    mock_result.returncode = 0
    mock_git_subprocess.return_value = mock_result


@pytest.fixture
def mock_git_status_dirty(mock_git_subprocess):
    """Mock git status returning changes."""
    mock_result = MagicMock()
    mock_result.stdout = "M  file1.py\nM  file2.py\n"
    mock_result.returncode = 0
    mock_git_subprocess.return_value = mock_result


@pytest.fixture
def mock_git_dry_run_no_files(mock_git_subprocess):
    """Mock git add --dry-run returning no files."""
    mock_result = MagicMock()
    mock_result.stdout = ""
    mock_result.returncode = 0
    mock_git_subprocess.return_value = mock_result


@pytest.fixture
def mock_git_dry_run_with_files(mock_git_subprocess):
    """Mock git add --dry-run returning files."""
    mock_result = MagicMock()
    mock_result.stdout = "add 'file1.py'\nadd 'file2.py'\n"
    mock_result.returncode = 0
    mock_git_subprocess.return_value = mock_result


@pytest.fixture
def temp_config_file(tmp_path):
    """Create a temporary config file."""

    def _create_config(content: str, global_config: bool = False):
        if global_config:
            # Simulate global config in temp directory
            config_dir = tmp_path / ".claude"
        else:
            # Simulate project config
            config_dir = tmp_path / ".claude"
        config_dir.mkdir(parents=True, exist_ok=True)
        config_file = config_dir / "safety-hooks-config.yaml"
        config_file.write_text(content)
        return config_file

    return _create_config


@pytest.fixture
def clear_config_cache():
    """Clear config cache before/after tests."""
    from config import clear_config_cache

    clear_config_cache()
    yield
    clear_config_cache()
