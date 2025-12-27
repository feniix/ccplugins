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
import re
import sys

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


def check_rm_command(command):
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

    # Get the command being executed
    command = data.get("tool_input", {}).get("command", "")

    should_block, reason = check_rm_command(command)

    if should_block:
        print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))
    else:
        print(json.dumps({"decision": "approve"}))

    sys.exit(0)
