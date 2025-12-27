#!/usr/bin/env python3
"""
RM Block Hook - Blocks `rm` commands and suggests using TRASH directory instead.

Configuration via .claude-plugin/safety-hooks-config.yaml:
- enabled_hooks.rm_block: Enable/disable this hook
- rm_block.trash_dir: Name of trash directory (default: "TRASH")
- rm_block.require_log: Whether to require logging trashed files (default: true)
- rm_block.log_file: Name of log file for trashed files (default: "TRASH-FILES.md")
"""

import json
import os
import re
import sys
from pathlib import Path

# Import config module for runtime configuration
try:
    from config import get_config  # type: ignore[no-redef]
except ImportError:
    # Fallback if config module not available
    def get_config():  # type: ignore[no-redef]
        class DefaultConfig:
            rm_block_enabled = True
            rm_trash_dir = "TRASH"
            rm_require_log = True
            rm_log_file = "TRASH-FILES.md"

        return DefaultConfig()


def ensure_gitignore_entries(cwd, trash_dir, log_file):
    """
    Add TRASH directory and log file to .gitignore at the repository root
    if in a git repository and not already present. Silently does nothing
    if not in a git repo.

    The patterns TRASH/ and TRASH-FILES.md will match these files/directories
    anywhere in the repository (recursive matching).
    """
    # Find the git repository root
    repo_root = None
    try:
        current = Path(cwd).resolve()
        for _ in range(50):  # Limit parent traversal to avoid infinite loops
            if (current / ".git").exists():
                repo_root = current
                break
            if current.parent == current:  # Reached filesystem root
                break
            current = current.parent
    except (OSError, PermissionError):
        pass  # Cannot determine git status

    if not repo_root:
        return  # Not in a git repo, nothing to do

    gitignore_path = repo_root / ".gitignore"

    # Read existing .gitignore if it exists
    existing_entries = set()
    if gitignore_path.exists():
        try:
            with open(gitignore_path, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        existing_entries.add(line)
        except (OSError, PermissionError, UnicodeDecodeError):
            return  # Cannot read .gitignore, skip

    # Check if entries already exist (with or without trailing slash)
    trash_variations = {trash_dir, f"{trash_dir}/"}

    needs_trash = not any(v in existing_entries for v in trash_variations)
    needs_log = log_file not in existing_entries

    if not needs_trash and not needs_log:
        return  # Already configured

    # Append missing entries
    try:
        with open(gitignore_path, "a", encoding="utf-8") as f:
            # Add newline if file doesn't end with one
            if gitignore_path.exists() and gitignore_path.stat().st_size > 0:
                f.seek(0, 2)  # Seek to end
                if f.tell() > 0:
                    f.seek(f.tell() - 1)
                    last_char = f.read(1)
                    if last_char not in ("\n", "\r"):
                        f.write("\n")

            f.write("\n# Safety-hooks: TRASH directory and log file (anywhere in repo)\n")
            if needs_trash:
                f.write(f"{trash_dir}/\n")
            if needs_log:
                f.write(f"{log_file}\n")
    except (OSError, PermissionError):
        pass  # Silently fail if we cannot write


def check_rm_command(command, cwd=None):
    """
    Check if a command contains rm that should be blocked.
    Returns tuple: (should_block: bool, reason: str or None)
    Returns (False, None) if hook is disabled.
    """
    # Load config to check if hook is enabled
    config = get_config()
    if not config.rm_block_enabled:
        return False, None

    # Normalize the command
    normalized_cmd = " ".join(command.strip().split())

    # Check if it's an rm command
    # This catches: rm, /bin/rm, /usr/bin/rm, etc.
    # Also simpler check: if the command starts with rm or contains rm after common separators
    if (
        normalized_cmd.startswith("rm ")
        or normalized_cmd == "rm"
        or re.search(r"(^|[;&|]\s*)(/\S*/)?rm\b", normalized_cmd)
    ):
        trash_dir = config.rm_trash_dir
        log_file = config.rm_log_file

        # Ensure .gitignore entries if in a git repository
        if cwd:
            ensure_gitignore_entries(cwd, trash_dir, log_file)

        if config.rm_require_log:
            reason_text = (
                f"Instead of using 'rm':\\n"
                f"- MOVE files using `mv` to the {trash_dir} directory in the CURRENT folder "
                f"(create it if needed), \\n"
                f"- Add an entry in a markdown file called '{log_file}' in the current directory, "
                f" where you show a one-liner with the file name, where it moved, and the reason to trash it, "
                f"e.g.:\\n\\n"
                "```\\n"
                "test_script.py - moved to TRASH/ - temporary test script\\n"
                "data/junk.txt - moved to TRASH/ - data file we don't need\\n"
                "```"
            )
        else:
            reason_text = (
                f"Instead of using 'rm':\\n"
                f"- MOVE files using `mv` to the {trash_dir} directory in the CURRENT folder "
                f"(create it if needed)"
            )
        return True, reason_text

    return False, None


# If run as a standalone script
if __name__ == "__main__":
    data = json.load(sys.stdin)

    # Check if this is a Bash tool call
    tool_name = data.get("tool_name")
    if tool_name != "Bash":
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # Get the command being executed and current working directory
    command = data.get("tool_input", {}).get("command", "")
    cwd = data.get("tool_input", {}).get("cwd") or os.getcwd()

    should_block, reason = check_rm_command(command, cwd)

    if should_block:
        print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))
    else:
        print(json.dumps({"decision": "approve"}))

    sys.exit(0)
