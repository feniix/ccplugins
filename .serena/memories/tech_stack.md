# Tech Stack & Coding Conventions

## Programming Languages
- **Python** - Hook scripts, configuration loader
- **Bash** - Test suite, shell scripts
- **YAML** - Configuration files
- **JSON** - Manifests (marketplace, plugins, hooks)

## Python Style
- Type hints required (Python 3.10+ style: `dict[str, int]`)
- Dataclasses for configuration
- Line length: 110 characters (ruff setting)

## Linting & Formatting
```bash
# Lint
ruff check .

# Format
ruff format .

# Pre-commit hooks (auto-run on git commit)
pre-commit run --all-files
```

## Testing
- **Pure bash tests** - No pytest, no bats-core, no jq dependency
- **Python for JSON parsing** in test helpers (via `_PYTHON_JSON_HELPER`)
- **53 tests total** covering all hook behaviors
- Test pattern: Pipe JSON to hook via stdin, check exit code and output

### Running Tests
```bash
# All tests (from plugins/safety-hooks/)
bash tests/run_all_tests.sh

# Individual test files
bash tests/test_git_add.sh
bash tests/test_rm_block.sh  # Includes 4 gitignore tests
bash tests/test_file_length.sh
```

### Test Coverage
| Test File | Coverage |
|-----------|----------|
| `test_config.sh` | Config module imports, defaults |
| `test_git_add.sh` | Git add wildcard/pattern blocking |
| `test_git_checkout.sh` | Git checkout force/dot protection |
| `test_git_commit.sh` | Git commit approval |
| `test_env_protection.sh` | .env file access blocking |
| `test_file_length.sh` | File length limit validation |
| `test_rm_block.sh` | RM blocking + 4 gitignore auto-add tests |

### Test Framework Location
`plugins/safety-hooks/tests/test_helpers.sh`

Key helpers:
- `make_hook_input()` - Generate hook input JSON
- `assert_exit_code()` - Assert exit code equals expected
- `assert_contains()` - Assert string contains substring
- `assert_json_value()` - Assert JSON key has expected value (handles both flat and nested formats)

## Config Locations
- Global: `~/.claude/plugins/safety-hooks-config.yaml`
- Project: `.claude/plugins/safety-hooks-config.yaml`
- Configs merge: defaults → global → project (project overrides)

## Hook Output Formats
Two formats exist (hooks differ):
- Flat: `{"decision": "block"}`
- Nested: `{"hookSpecificOutput": {"permissionDecision": "ask"}}`

Tests must handle both formats via the Python JSON helper.
