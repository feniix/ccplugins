#!/usr/bin/env python3
"""
Git push/pull hook that asks for user permission before allowing push or pull.
Uses the "ask" decision type to prompt user in the UI.

Configuration via .claude-plugin/safety-hooks-config.yaml:
- enabled_hooks.git_push_pull_ask: Enable/disable this hook
"""

import json
import os
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
            git_push_pull_ask_enabled = True

        return DefaultConfig()


def check_git_push_pull_command(command):
    """
    Check if a command contains a git push or git pull and request user permission.
    Handles compound commands (e.g., "cd /path && git push origin main").
    Returns tuple: (decision: str, reason: str or None)
    decision is one of: "allow", "ask", "block"
    Returns ("allow", None) if hook is disabled.
    """
    # Load config to check if hook is enabled
    config = get_config()
    if not config.git_push_pull_ask_enabled:
        return "allow", None

    # Check each subcommand in compound commands
    for subcmd in extract_subcommands(command):
        normalized = " ".join(subcmd.strip().split())
        if normalized.startswith("git push"):
            reason = "Git push requires your approval."
            return "ask", reason
        if normalized.startswith("git pull"):
            reason = "Git pull requires your approval."
            return "ask", reason

    return "allow", None


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

    decision, reason = check_git_push_pull_command(command)

    if decision == "ask":
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "ask",
                        "permissionDecisionReason": reason,
                    }
                }
            )
        )
    elif decision == "block":
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "deny",
                        "permissionDecisionReason": reason,
                    }
                }
            )
        )
    else:
        print(json.dumps({"decision": "approve"}))

    sys.exit(0)
