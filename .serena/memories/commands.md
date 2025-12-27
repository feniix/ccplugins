# Common Commands

## Safety Hooks Testing
```bash
# Run all tests (53 tests total)
cd plugins/safety-hooks && bash tests/run_all_tests.sh

# Run specific test file
bash tests/test_git_add.sh
bash tests/test_git_checkout.sh
bash tests/test_git_commit.sh
bash tests/test_env_protection.sh
bash tests/test_file_length.sh
bash tests/test_rm_block.sh  # Includes 4 gitignore tests
bash tests/test_config.sh
```

## Linting & Formatting
```bash
# Check code
ruff check .

# Format code
ruff format .

# Run pre-commit hooks manually
pre-commit run --all-files
```

## Plugin Testing (Local)
```bash
# From repo root
claude
/plugin marketplace add .
/plugin install safety-hooks@ccplugins
```

## Git Operations
```bash
# Commit with pre-commit hooks
git commit -m "message"  # Pre-commit runs automatically

# Skip pre-commit if needed
git commit --no-verify -m "message"
```
