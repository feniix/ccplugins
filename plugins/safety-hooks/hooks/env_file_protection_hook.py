#!/usr/bin/env python3
"""
Hook to protect .env files from being read or searched.
Blocks commands that would expose .env contents and suggests safer alternatives.

Configuration via .claude/plugins/safety-hooks-config.yaml:
- enabled_hooks.env_protection: Enable/disable this hook
- env_protection.ignore_patterns: List of regex patterns for .env files to ignore
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
            env_protection_enabled = True
            env_protection_ignore_patterns = None

        return DefaultConfig()


def _extract_env_path(command: str) -> str | None:
    """Extract the .env file path from a command, if present."""
    # Try to find .env file paths in various positions
    patterns = [
        r'(["\']?)([^\s"\']+\.[Ee][Nn][Vv])\1',  # Quoted or unquoted .env paths
        r"\.env(?:\.\w+)?",  # .env, .env.local, .env.example, etc.
    ]

    for pattern in patterns:
        match = re.search(pattern, command, re.IGNORECASE)
        if match:
            # For patterns with groups, try to return group 2 (the actual path)
            # For single-group patterns, return group 0 (the whole match)
            if match.lastindex and match.lastindex >= 2:
                return match.group(2)
            return match.group(0)
    return None


def _should_ignore_env_file(env_path: str, ignore_patterns: list[str] | None) -> bool:
    """Check if an .env file path matches any ignore pattern."""
    if not ignore_patterns:
        return False

    for pattern in ignore_patterns:
        try:
            if re.search(pattern, env_path):
                return True
        except re.error:
            # Invalid regex pattern, skip it
            continue
    return False


def check_env_file_access(command):
    """
    Check if a command attempts to read, write, or edit .env files.
    Returns tuple: (should_block: bool, reason: str or None)
    Returns (False, None) if hook is disabled or env file is ignored.
    """
    # Load config to check if hook is enabled
    config = get_config()
    if not config.env_protection_enabled:
        return False, None

    # Normalize the command
    normalized_cmd = " ".join(command.strip().split())

    # Patterns that indicate reading, writing, or editing .env files
    env_patterns = [
        # Direct file reading
        r"\bcat\s+.*\.env\b",
        r"\bless\s+.*\.env\b",
        r"\bmore\s+.*\.env\b",
        r"\bhead\s+.*\.env\b",
        r"\btail\s+.*\.env\b",
        # Editors - both reading and writing
        r"\bnano\s+.*\.env\b",
        r"\bvi\s+.*\.env\b",
        r"\bvim\s+.*\.env\b",
        r"\bemacs\s+.*\.env\b",
        r"\bcode\s+.*\.env\b",
        r"\bsubl\s+.*\.env\b",
        r"\batom\s+.*\.env\b",
        r"\bgedit\s+.*\.env\b",
        # Writing/modifying .env files
        r">\s*\.env\b",  # Redirect to .env
        r">>\s*\.env\b",  # Append to .env
        r"\becho\s+.*>\s*\.env\b",
        r"\becho\s+.*>>\s*\.env\b",
        r"\bprintf\s+.*>\s*\.env\b",
        r"\bprintf\s+.*>>\s*\.env\b",
        r"\bsed\s+.*-i.*\.env\b",  # sed in-place editing
        r"\bawk\s+.*>\s*\.env\b",
        r"\btee\s+.*\.env\b",
        r"\bcp\s+.*\.env\b",  # Copying to .env
        r"\bmvo?i?s?\s+.*\.env\b",  # Moving to .env
        r"\btouch\s+.*\.env\b",  # Creating .env
        # Searching/grepping .env files
        r"\bgrep\s+.*\.env\b",
        r"\bgrep\s+.*\s+\.env\b",
        r"\brg\s+.*\.env\b",
        r"\brg\s+.*\s+\.env\b",
        r"\bag\s+.*\.env\b",
        r"\back\s+.*\.env\b",
        r'\bfind\s+.*-name\s+["\']?\.env',
        # Other ways to expose .env contents
        r"\becho\s+.*\$\(.*cat\s+.*\.env.*\)",
        r"\bprintf\s+.*\$\(.*cat\s+.*\.env.*\)",
        # Also check for patterns without the dot (like "env" file)
        r'\bcat\s+["\']?env["\']?\s*$',
        r'\bcat\s+["\']?env["\']?\s*[;&|]',
        r'\bless\s+["\']?env["\']?\s*$',
        r'\bless\s+["\']?env["\']?\s*[;&|]',
        r'>\s*["\']?env["\']?\s*$',
        r'>>\s*["\']?env["\']?\s*$',
    ]

    # Check if any pattern matches
    for pattern in env_patterns:
        if re.search(pattern, normalized_cmd, re.IGNORECASE):
            # Extract the .env path and check if it should be ignored
            env_path = _extract_env_path(normalized_cmd)
            if env_path and _should_ignore_env_file(env_path, config.env_protection_ignore_patterns):
                return False, None

            reason_text = (
                "Blocked: Direct access to .env files is not allowed for security reasons.\\n\\n"
                "• Reading .env files could expose sensitive values\\n"
                "• Writing/editing .env files should be done manually outside Claude Code\\n\\n"
                "For safe inspection, use the `env-safe` command:\\n"
                " • `env-safe list` - List all environment variable keys\\n"
                " • `env-safe list --status` - Show keys with defined/empty status\\n"
                " • `env-safe check KEY_NAME` - Check if a specific key exists\\n"
                " • `env-safe count` - Count variables in the file\\n"
                " • `env-safe validate` - Check .env file syntax\\n"
                " • `env-safe --help` - See all options\\n\\n"
                "To modify .env files, please edit them manually outside of Claude Code."
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

    should_block, reason = check_env_file_access(command)

    if should_block:
        print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))
    else:
        print(json.dumps({"decision": "approve"}))

    sys.exit(0)
