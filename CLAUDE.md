# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Claude plugin marketplace (ccplugins) - a manifest registry of plugins distributed through Claude Code's plugin system.

## Marketplace Architecture

This is **not a traditional code project**. It's a declarative plugin system—no build process, npm install, or compilation required. Plugins are interpreted directly from source.

### Two-Level Manifest System

1. **Marketplace manifest** (`.claude-plugin/marketplace.json`): Lists all plugins with `name`, `description`, `version`, `source` paths
2. **Plugin manifests** (each plugin's `.claude-plugin/plugin.json`): Defines metadata; `name` is required (kebab-case)

### Plugin Types

- **Commands** (`commands/*.md`): Markdown with YAML frontmatter; filename becomes slash command
- **Hooks** (`hooks/hooks.json`): Event-driven automation (PreToolUse, etc.)
- **Agents** (`agents/*.md`): Subagent definitions
- **Skills** (`skills/*/SKILL.md`): Model-invoked capabilities

### Constraint

All paths in manifests must be relative and start with `./`. Plugin names must be kebab-case.

## Safety Hooks Plugin Architecture

The safety-hooks plugin (`plugins/safety-hooks/`) is the main plugin. It implements a **unified hook dispatcher pattern**:

### Entry Points

| Hook File | Purpose |
|-----------|---------|
| `hooks/bash_hook.py` | Unified dispatcher for all Bash command checks |
| `hooks/file_length_limit_hook.py` | Direct hook for Edit/Write operations |

### Hook Output Formats

Two formats exist—tests handle both:

- **Flat**: `{"decision": "block"}`
- **Nested**: `{"hookSpecificOutput": {"permissionDecision": "deny", "permissionDecisionReason": "..."}}`

### Configuration System

Config files merge in priority: **defaults → global → project**

- Global: `~/.claude/plugins/safety-hooks-config.yaml`
- Project: `.claude/plugins/safety-hooks-config.yaml`

Python modules (`config.py`):
- `SafetyHooksConfig` dataclass defines all settings
- `load_config()` reads and merges YAML files
- `get_config()` returns cached config singleton

### Hook Check Functions

Each individual hook module exports a `check_*_command(command, cwd=None)` function that returns `(decision, reason)` where `decision` is `"block"`, `"ask"`, or `"allow"`.

The `bash_hook.py` dispatcher:
1. Imports all check functions
2. Runs each check sequentially
3. Combines results: block > ask > allow (priority order)
4. Outputs nested JSON format for deny/ask decisions

## Development Commands

### Linting & Formatting

```bash
# Lint Python (excludes test files)
ruff check plugins/

# Format Python
ruff format plugins/

# Run all pre-commit hooks
pre-commit run --all-files

# Skip pre-commit for a commit
git commit --no-verify -m "message"
```

### Testing Safety Hooks

```bash
# Run all tests (53 tests, pure bash)
cd plugins/safety-hooks && bash tests/run_all_tests.sh

# Run individual test file
bash tests/test_rm_block.sh  # Includes gitignore auto-add tests
```

**Test framework**: `tests/test_helpers.sh` provides bash testing helpers. No pytest, no bats, no jq dependency.

### Local Plugin Testing

```bash
# Add marketplace from repo root
claude
/plugin marketplace add .

# Install plugin
/plugin install safety-hooks@ccplugins
```

### Version Bumping

When releasing plugin updates, use the version bump script to update both manifests atomically:

```bash
# List available plugins and current versions
python3 scripts/bump_version.py --list

# Bump patch version (0.2.0 -> 0.2.1)
python3 scripts/bump_version.py safety-hooks patch

# Bump minor version (0.2.0 -> 0.3.0)
python3 scripts/bump_version.py safety-hooks minor

# Bump major version (0.2.0 -> 1.0.0)
python3 scripts/bump_version.py safety-hooks major

# Set specific version explicitly
python3 scripts/bump_version.py safety-hooks 1.0.0

# Preview changes without writing files
python3 scripts/bump_version.py safety-hooks patch --dry-run
```

**Important**: The script updates two files that must stay in sync:
- `.claude-plugin/marketplace.json` - marketplace manifest
- `plugins/{name}/.claude-plugin/plugin.json` - plugin's own manifest

## Adding a New Plugin

```bash
# 1. Create directory structure
mkdir -p plugins/new-plugin/.claude-plugin

# 2. Create plugin manifest
cat > plugins/new-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "new-plugin",
  "version": "1.0.0",
  "description": "Brief description"
}
EOF

# 3. Add to .claude-plugin/marketplace.json plugins array
# 4. Create README.md in plugin directory
```

## Python Style

- Type hints required (Python 3.10+ style: `dict[str, int]`)
- Dataclasses for configuration
- Line length: 110 characters
- Test files excluded from linting (pattern: `^plugins/.*/tests/.*$`)
