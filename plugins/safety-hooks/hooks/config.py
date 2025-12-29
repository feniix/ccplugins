"""Configuration loader for safety hooks.

Users can customize hook behavior by creating config files at:
- Project level: .claude/plugins/safety-hooks-config.yaml (overrides global)
- Global/user level: ~/.claude/plugins/safety-hooks-config.yaml (fallback defaults)

Configs are merged: defaults → global → project (project overrides global).
If no config file exists, default values are used.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass
class SafetyHooksConfig:
    """Configuration for safety hooks behavior."""

    # Enable/disable individual hooks
    rm_block_enabled: bool = True
    git_add_block_enabled: bool = True
    git_checkout_block_enabled: bool = True
    git_commit_ask_enabled: bool = True
    git_push_pull_ask_enabled: bool = True
    env_protection_enabled: bool = True
    file_length_limit_enabled: bool = True

    # File length limit settings
    file_max_lines: int = 10000
    file_extensions: list[str] | None = None  # None = use default list

    # RM block settings
    rm_trash_dir: str = "TRASH"
    rm_require_log: bool = True
    rm_log_file: str = "TRASH-FILES.md"

    # Git add block settings
    git_allow_wildcards: bool = False
    git_allow_dot_add: bool = False
    git_allow_all_flag: bool = False

    # Git checkout settings
    git_checkout_force_protection: bool = True
    git_checkout_dot_protection: bool = True

    # Env protection settings
    env_protection_ignore_patterns: list[str] | None = None  # Patterns for .env files to ignore


# Default source code extensions (when not specified in config)
DEFAULT_SOURCE_CODE_EXTENSIONS: set[str] = {
    # Python
    ".py",
    ".pyi",
    ".pyx",
    # JavaScript/TypeScript
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".mjs",
    ".cjs",
    ".d.ts",
    # Web
    ".vue",
    ".svelte",
    ".astro",
    # Systems languages
    ".c",
    ".cpp",
    ".cc",
    ".cxx",
    ".h",
    ".hpp",
    ".hxx",
    ".rs",
    ".go",
    # JVM languages
    ".java",
    ".kt",
    ".kts",
    ".scala",
    ".groovy",
    ".cljs",
    ".cljc",
    # Microsoft
    ".cs",
    ".vb",
    ".fs",
    ".fsi",
    # Scripting
    ".rb",
    ".php",
    ".swift",
    ".dart",
    ".lua",
    ".pl",
    ".pm",
    ".sh",
    ".bash",
    ".zsh",
    ".fish",
    ".ps1",
    ".psm1",
    # Data/Stats
    ".r",
    ".rmd",
    ".jl",
    # Functional
    ".hs",
    ".ml",
    ".mli",
    ".re",
    ".rei",
    ".ex",
    ".exs",
    ".erl",
    ".hrl",
    # Config/Data formats
    ".yaml",
    ".yml",
    ".toml",
    ".xml",
    ".sql",
    ".graphql",
    ".gql",
    ".proto",
    # Other
    ".scm",
    ".ss",
    ".lisp",
    ".lsp",
    ".cl",
    ".fsx",
    ".v",
    ".sv",
    ".svh",
    ".nim",
    ".zig",
    ".ada",
    ".adb",
    ".ads",
}


def get_config_paths() -> tuple[Path, Path]:
    """Get paths to global and project config files.

    Returns:
        (global_config_path, project_config_path)
    """
    home = Path.home()
    global_config = home / ".claude" / "plugins" / "safety-hooks-config.yaml"
    project_config = Path.cwd() / ".claude" / "plugins" / "safety-hooks-config.yaml"
    return global_config, project_config


def _apply_config_data(config: SafetyHooksConfig, data: dict[str, Any]) -> None:
    """Apply config data from a YAML dict to the config object."""
    if not data:
        return

    if "enabled_hooks" in data:
        enabled = data["enabled_hooks"]
        config.rm_block_enabled = enabled.get("rm_block", config.rm_block_enabled)
        config.git_add_block_enabled = enabled.get("git_add_block", config.git_add_block_enabled)
        config.git_checkout_block_enabled = enabled.get(
            "git_checkout_block", config.git_checkout_block_enabled
        )
        config.git_commit_ask_enabled = enabled.get("git_commit_ask", config.git_commit_ask_enabled)
        config.git_push_pull_ask_enabled = enabled.get("git_push_pull_ask", config.git_push_pull_ask_enabled)
        config.env_protection_enabled = enabled.get("env_protection", config.env_protection_enabled)
        config.file_length_limit_enabled = enabled.get("file_length_limit", config.file_length_limit_enabled)

    if "file_length_limit" in data:
        fll = data["file_length_limit"]
        config.file_max_lines = fll.get("max_lines", config.file_max_lines)
        config.file_extensions = fll.get("extensions", config.file_extensions)

    if "rm_block" in data:
        rm = data["rm_block"]
        config.rm_trash_dir = rm.get("trash_dir", config.rm_trash_dir)
        config.rm_require_log = rm.get("require_log", config.rm_require_log)
        config.rm_log_file = rm.get("log_file", config.rm_log_file)

    if "git_add_block" in data:
        ga = data["git_add_block"]
        config.git_allow_wildcards = ga.get("allow_wildcards", config.git_allow_wildcards)
        config.git_allow_dot_add = ga.get("allow_dot_add", config.git_allow_dot_add)
        config.git_allow_all_flag = ga.get("allow_all_flag", config.git_allow_all_flag)

    if "git_checkout" in data:
        gc = data["git_checkout"]
        config.git_checkout_force_protection = gc.get(
            "force_protection", config.git_checkout_force_protection
        )
        config.git_checkout_dot_protection = gc.get("dot_protection", config.git_checkout_dot_protection)

    if "env_protection" in data:
        ep = data["env_protection"]
        config.env_protection_ignore_patterns = ep.get(
            "ignore_patterns", config.env_protection_ignore_patterns
        )


def load_config() -> SafetyHooksConfig:
    """Load configuration from files and merge them.

    Merge order: defaults → global config → project config
    Project settings override global settings.
    """
    config = SafetyHooksConfig()
    global_config, project_config = get_config_paths()

    try:
        import yaml

        # Load and merge global config first
        if global_config.exists():
            global_data = yaml.safe_load(global_config.read_text())
            _apply_config_data(config, global_data or {})

        # Then load and merge project config (overrides global)
        if project_config.exists():
            project_data = yaml.safe_load(project_config.read_text())
            _apply_config_data(config, project_data or {})

    except Exception:
        # If config is invalid, use current config (with defaults or partial merges)
        pass

    return config


def get_source_code_extensions() -> set[str]:
    """Get the configured source code extensions."""
    config = load_config()

    if config.file_extensions:
        if "auto" in config.file_extensions or not config.file_extensions:
            return DEFAULT_SOURCE_CODE_EXTENSIONS
        return set(config.file_extensions)

    return DEFAULT_SOURCE_CODE_EXTENSIONS


# Cached config for performance
_cached_config: SafetyHooksConfig | None = None


def get_config() -> SafetyHooksConfig:
    """Get cached configuration or load it."""
    global _cached_config
    if _cached_config is None:
        _cached_config = load_config()
    return _cached_config


def clear_config_cache() -> None:
    """Clear the config cache (call after editing config file)."""
    global _cached_config
    _cached_config = None
