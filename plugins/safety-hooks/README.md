# Safety Hooks Plugin

Safety hooks to block or require user approval for dangerous commands in Claude Code.

## Features

- **Blocks `rm` commands** - Redirects to use a TRASH directory instead
- **Protects `.env` files** - Blocks reading/writing `.env` files for security
- **Git operation safeguards**:
  - Blocks dangerous `git add` patterns (wildcards, `-A`, `.`, `../`)
  - Requires approval for `git commit`
  - Blocks dangerous `git checkout` operations that discard changes
- **File size limits** - Asks for approval when source code files would exceed 10,000 lines; defers to system settings for normal files

## Installation

```bash
/plugin install safety-hooks@ccplugins
```

## Configuration

All hooks can be configured via a YAML config file without modifying source code.

### Config File Locations

The plugin looks for config files in two locations and **merges** them:

1. **Global**: `~/.claude/plugins/safety-hooks-config.yaml` (default settings for all projects)
1. **Project-level**: `.claude/plugins/safety-hooks-config.yaml` (overrides global settings)

Merge order: defaults → global → project. You can set sensible defaults globally and override specific settings per project.

### Creating the Config File

For global settings (applies to all projects):

```bash
mkdir -p ~/.claude/plugins
cat > ~/.claude/plugins/safety-hooks-config.yaml << 'EOF'
# Global defaults
enabled_hooks:
  file_length_limit: true
  git_commit_ask: true
file_length_limit:
  max_lines: 10000
EOF
```

For project-specific overrides:

```bash
mkdir -p .claude/plugins
cat > .claude/plugins/safety-hooks-config.yaml << 'EOF'
# Override just this setting for this project
file_length_limit:
  max_lines: 5000  # Stricter limit for this project
EOF
```

### Example Config

```yaml
# Enable or disable individual hooks
enabled_hooks:
  rm_block: true           # Block 'rm' commands
  git_add_block: true      # Block dangerous git add patterns
  git_checkout_block: true # Block dangerous git checkout patterns
  git_commit_ask: true     # Ask before git commit
  env_protection: true     # Protect .env files from access
  file_length_limit: true  # Ask before creating very large files

# File length limit settings
file_length_limit:
  max_lines: 10000         # Maximum lines before prompting

# RM block settings
rm_block:
  trash_dir: "TRASH"       # Name of trash directory
  require_log: true        # Require logging trashed files
  log_file: "TRASH-FILES.md"  # Name of log file

# Git add block settings
git_add_block:
  allow_wildcards: false   # Allow wildcard patterns like *.py
  allow_dot_add: false     # Allow 'git add .'
  allow_all_flag: false    # Allow -A/--all flags

# Git checkout safety settings
git_checkout:
  force_protection: true   # Block -f/--force flags
  dot_protection: true     # Block 'git checkout .'

# Env protection settings
env_protection:
  ignore_patterns:
    - "\\.env\\..+"           # Ignore .env.local, .env.example, etc.
    - "\\.env\\.template$"    # Ignore template files
    - "docs/.*\\.env"         # Ignore .env files in docs
```

### Configuration Options

| Setting                          | Type       | Default | Description                             |
| -------------------------------- | ---------- | ------- | --------------------------------------- |
| `enabled_hooks.*`                | boolean    | true    | Enable/disable individual hooks         |
| `file_length_limit.max_lines`    | integer    | 10000   | Maximum lines before prompting          |
| `rm_block.trash_dir`             | string     | TRASH   | Name of trash directory                 |
| `rm_block.require_log`           | boolean    | true    | Require logging trashed files           |
| `git_add_block.allow_wildcards`  | boolean    | false   | Allow wildcard patterns in git add      |
| `git_add_block.allow_dot_add`    | boolean    | false   | Allow `git add .`                       |
| `git_checkout.force_protection`  | boolean    | true    | Block -f/--force flags in git checkout  |
| `git_checkout.dot_protection`    | boolean    | true    | Block `git checkout .`                  |
| `env_protection.ignore_patterns` | string\[\] | \[\]    | Regex patterns for .env files to ignore |

If no config file exists, all hooks use their default values. Settings in project config override global config.

## Hook Behaviors

| Hook              | Decision    | Behavior                                                                                 |
| ----------------- | ----------- | ---------------------------------------------------------------------------------------- |
| `rm` commands     | Block       | Always blocked, prompts to use TRASH directory                                           |
| `.env` access     | Block       | Always blocked for security                                                              |
| `git add *`       | Block       | Wildcards always blocked                                                                 |
| `git add -A/-a/.` | Block       | Dangerous patterns always blocked                                                        |
| `git add <dir>/`  | Ask         | Requires approval if modified files present                                              |
| `git commit`      | Ask         | Always requires approval                                                                 |
| `git checkout .`  | Block       | Blocked if uncommitted changes exist                                                     |
| File size limit   | Ask / Defer | Asks for approval when file would exceed 10,000 lines; defers to system for normal files |

## Files

- `hooks/bash_hook.py` - Main entry point for Bash command checks
- `hooks/file_length_limit_hook.py` - File size validation
- `hooks/rm_block_hook.py` - Blocks `rm` commands
- `hooks/env_file_protection_hook.py` - Protects `.env` files
- `hooks/git_add_block_hook.py` - Git add safety
- `hooks/git_checkout_safety_hook.py` - Git checkout safety
- `hooks/git_commit_block_hook.py` - Git commit approval
- `hooks/command_utils.py` - Shared utilities
- `hooks/config.py` - Configuration loader

## Testing

The plugin includes bash-based tests following the official Claude Code testing pattern:

```bash
# Run all tests
cd plugins/safety-hooks
bash tests/run_all_tests.sh

# Run individual test files
bash tests/test_git_add.sh
bash tests/test_rm_block.sh
bash tests/test_file_length.sh
```

**Test coverage:**

- `test_config.sh` - Config module imports and defaults
- `test_git_add.sh` - Git add wildcard/pattern blocking
- `test_git_checkout.sh` - Git checkout force/dot protection
- `test_git_commit.sh` - Git commit approval
- `test_env_protection.sh` - .env file access blocking
- `test_file_length.sh` - File length limit validation
- `test_rm_block.sh` - RM command blocking

## License

MIT
