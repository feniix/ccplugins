#!/usr/bin/env python3
"""
File Length Limit Hook

Behavior:
1. Large files (> configured limit): Returns "ask" - requires user approval
2. Normal files: Returns {} - system settings take over
3. Errors: Returns {} - defers to system

Configuration via .claude-plugin/safety-hooks-config.yaml:
- enabled_hooks.file_length_limit: Enable/disable this hook
- file_length_limit.max_lines: Maximum lines before prompting (default: 10000)
- file_length_limit.extensions: File extensions to check (default: auto)
"""

import json
import os
import sys
from pathlib import Path
from typing import Any

# Import config module for runtime configuration
try:
    from config import get_config, get_source_code_extensions  # type: ignore[no-redef]
except ImportError:
    # Fallback if config module not available
    def get_config():  # type: ignore[no-redef]
        class DefaultConfig:
            file_length_limit_enabled = True
            file_max_lines = 10000
            file_extensions = None

        return DefaultConfig()

    def get_source_code_extensions():
        from config import DEFAULT_SOURCE_CODE_EXTENSIONS

        return DEFAULT_SOURCE_CODE_EXTENSIONS


def is_source_code_file(file_path: str) -> bool:
    """Check if file is a source code file based on extension."""
    if not file_path:
        return False
    extensions = get_source_code_extensions()
    return Path(file_path).suffix.lower() in extensions


def count_lines_in_content(content: str) -> int:
    """Count number of lines in content string."""
    if not content:
        return 0
    return len(content.splitlines())


def get_resulting_line_count(tool_name: str, file_path: str, tool_input: dict[str, Any]) -> int:
    """
    Calculate the resulting line count after the tool operation.
    For Write: count lines in new content
    For Edit: count lines in file after replacement
    """
    if tool_name == "Write":
        # For Write, the new content is in the 'content' field
        content = tool_input.get("content", "")
        return count_lines_in_content(content)
    elif tool_name == "Edit":
        # For Edit, we need to calculate the result of the replacement
        old_string = tool_input.get("old_string", "")
        new_string = tool_input.get("new_string", "")

        # Get current file content if it exists
        if os.path.exists(file_path):
            try:
                with open(file_path, encoding="utf-8") as f:
                    current_content: str = f.read()
            except Exception:
                # If we can't read the file, assume it's safe
                return 0
        else:
            # File doesn't exist yet, assume it's safe
            return 0

        # Calculate the result of the edit
        # Note: The replace_all parameter determines if all occurrences
        # are replaced
        replace_all = tool_input.get("replace_all", False)
        if replace_all:
            result_content = current_content.replace(old_string, new_string)
        else:
            # Replace only first occurrence
            result_content = current_content.replace(old_string, new_string, 1)
        return count_lines_in_content(result_content)
    return 0


def check_file_length_limit(data: dict[str, Any]) -> dict[str, str]:
    """
    Check if file operation would exceed MAX_FILE_LINES limit.
    Returns:
        - {"decision": "ask", "reason": "..."} for large files
        - {} for normal files (defer to system settings)
        - {} if hook is disabled
    """
    try:
        # Load config to check if hook is enabled
        config = get_config()
        if not config.file_length_limit_enabled:
            return {}

        tool_name: str | None = data.get("tool_name")

        # Only check Edit and Write tools
        if tool_name not in ("Edit", "Write"):
            return {}

        tool_input: dict[str, Any] = data.get("tool_input", {})
        file_path: str = tool_input.get("file_path", "")

        # Only check source code files
        if not is_source_code_file(file_path):
            return {}

        # Calculate resulting line count
        resulting_lines: int = get_resulting_line_count(tool_name, file_path, tool_input)

        # Get configured max lines
        max_lines = config.file_max_lines

        # If under limit, defer to system settings
        if resulting_lines <= max_lines:
            return {}

        # Large file - require user approval
        reason: str = f"""**File length limit exceeded ({resulting_lines} lines > {max_lines} lines).**

The resulting file `{file_path}` would be {resulting_lines} lines long.
To maintain code quality and modularity, files should be kept under {max_lines} lines.

Would you like me to:
1. Refactor the code into smaller, more modular files?
2. Proceed with the large file anyway?"""

        return {"decision": "ask", "reason": reason}

    except Exception:
        # On error, defer to system settings
        return {}


# Main execution
if __name__ == "__main__":
    data: dict[str, Any] = json.load(sys.stdin)
    result: dict[str, str] = check_file_length_limit(data)

    if result:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": result.get("decision", "ask"),
                        "permissionDecisionReason": result.get("reason", ""),
                    }
                }
            )
        )
    else:
        print(json.dumps({}))

    sys.exit(0)
