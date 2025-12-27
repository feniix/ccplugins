#!/usr/bin/env python3
"""
Git checkout safety hook - Blocks dangerous git checkout patterns.

Configuration via .claude-plugin/safety-hooks-config.yaml:
- enabled_hooks.git_checkout_block: Enable/disable this hook
- git_checkout.force_protection: Block -f/--force flags (default: true)
- git_checkout.dot_protection: Block 'git checkout .' (default: true)
"""

import os
import re
import subprocess
import sys

# Add plugin hooks directory to Python path for local imports
PLUGIN_ROOT = os.environ.get("CLAUDE_PLUGIN_ROOT")
if PLUGIN_ROOT:
    hooks_dir = os.path.join(PLUGIN_ROOT, "hooks")
    if hooks_dir not in sys.path:
        sys.path.insert(0, hooks_dir)

from command_utils import extract_subcommands

# Import config module for runtime configuration
try:
    from config import get_config  # type: ignore[no-redef]
except ImportError:
    # Fallback if config module not available
    def get_config():  # type: ignore[no-redef]
        class DefaultConfig:
            git_checkout_block_enabled = True
            git_checkout_force_protection = True
            git_checkout_dot_protection = True

        return DefaultConfig()


def check_git_checkout_command(command):
    """
    Check if a git checkout command is safe to execute.
    Handles compound commands (e.g., "cd /path && git checkout branch").
    Returns tuple: (should_block: bool, reason: str or None)
    Returns (False, None) if hook is disabled.
    """
    # Load config to check if hook is enabled
    config = get_config()
    if not config.git_checkout_block_enabled:
        return False, None

    # Check each subcommand in compound commands
    for subcmd in extract_subcommands(command):
        result = _check_single_git_checkout_command(subcmd, config)
        should_block, reason = result
        if should_block:
            return result

    return False, None


def _check_single_git_checkout_command(command, config=None):
    """
    Check a single (non-compound) git checkout command.
    Returns tuple: (should_block: bool, reason: str or None)
    """
    if config is None:
        config = get_config()

    # Check if it's a git checkout command
    if not command.strip().startswith("git checkout"):
        return False, None

    # Safe patterns that we should allow without checking
    if "-b" in command or "--help" in command or "-h" in command:
        return False, None

    # Build dangerous patterns list based on config
    dangerous_patterns = []

    # Force flag protection (if enabled)
    if config.git_checkout_force_protection:
        dangerous_patterns.append(
            (
                r"\bgit\s+checkout\s+(-f|--force)\b",
                "'git checkout -f' FORCES checkout and DISCARDS all uncommitted changes!",
            )
        )

    # Dot protection (if enabled)
    if config.git_checkout_dot_protection:
        dangerous_patterns.extend(
            [
                (r"\bgit\s+checkout\s+\.", "'git checkout .' will DISCARD ALL changes in current directory!"),
                (r"\bgit\s+checkout\s+.*\s+--\s+\.", "This will DISCARD ALL changes in current directory!"),
                (
                    r"\bgit\s+checkout\s+.*\s+--\s+",
                    "This will overwrite your local file with version from another branch/commit!",
                ),
            ]
        )

    for pattern, message in dangerous_patterns:
        if re.search(pattern, command):
            reason = f"⚠️ DANGEROUS COMMAND DETECTED!\\n\\n{message}\\n\\nThis command will destroy uncommitted work without warning.\\n\\nSafer alternatives:\\n- Use 'git stash' to save changes temporarily\\n- Use 'git diff' to see what would be lost\\n- Use 'git restore' for clearer syntax"
            return True, reason

    try:
        # First, check if there are any uncommitted changes
        status_result = subprocess.run(
            ["git", "status", "--porcelain"], capture_output=True, text=True, cwd=os.getcwd()
        )
        has_changes = bool(status_result.stdout.strip())

        # Get more detailed status if there are changes
        if has_changes:
            # Count changes
            all_changes = status_result.stdout.strip().split("\n")
            modified_files = [f for f in all_changes if f.strip()]
            num_changes = len(modified_files)

            # Build warning message
            warning = f"WARNING: You have {num_changes} uncommitted change(s) that may be lost!\\n\\n"
            if modified_files:
                warning += "Modified files:\\n"
                for change in modified_files[:10]:  # Show first 10
                    warning += f" {change}\\n"
                if num_changes > 10:
                    warning += f" ... and {num_changes - 10} more\\n"
            warning += "\\nOptions:\\n"
            warning += "1. Stash changes: git stash\\n"
            warning += "2. Commit changes: git commit -am 'your message'\\n"
            warning += "3. Discard changes: git restore <file>\\n"
            warning += "4. Use 'git switch' instead for safer branch switching\\n"

            # Special warning for checkout .
            if "checkout ." in command or "checkout -- ." in command:
                warning += "\\n⚠️ DANGER: 'git checkout .' will DISCARD ALL local changes!"
            return True, warning

    except Exception as e:
        # If we can't determine status, err on the side of caution
        reason = f"Could not verify repository status: {str(e)}\\nPlease manually check 'git status' before proceeding."
        return True, reason

    # No uncommitted changes, safe to proceed
    return False, None


# If run as a standalone script
if __name__ == "__main__":
    import json
    import sys

    data = json.load(sys.stdin)

    # Check if this is a Bash tool call
    tool_name = data.get("tool_name")
    if tool_name != "Bash":
        print(json.dumps({"decision": "approve"}))
        sys.exit(0)

    # Get the command being executed
    command = data.get("tool_input", {}).get("command", "")

    should_block, reason = check_git_checkout_command(command)

    if should_block:
        print(json.dumps({"decision": "block", "reason": reason}))
    else:
        print(json.dumps({"decision": "approve"}))

    sys.exit(0)
