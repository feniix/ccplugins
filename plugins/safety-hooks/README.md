# Safety Hooks Plugin

> Guards against accidental data loss in Claude Code—blocks `rm`, protects `.env` files, and enforces safer git workflows.

## Quick Start

```bash
/plugin install safety-hooks@ccplugins
```

All hooks active with sensible defaults. Try `rm important_file.txt` to see it in action.

## What's Protected

| Hook             | What It Blocks                         | What To Do Instead                         |
| ---------------- | -------------------------------------- | ------------------------------------------ |
| **RM**           | All `rm` commands                      | Use `mv file TRASH/`                       |
| **Env**          | Reading/writing `.env`                 | Manual edits only                          |
| **Git Add**      | `git add *`, `git add .`, `git add -A` | Use explicit paths: `git add path/to/file` |
| **Git Commit**   | All commits                            | Approve each commit manually               |
| **Git Checkout** | `git checkout .`, `git checkout -f`    | Commit or stash changes first              |
| **File Size**    | Source files >10,000 lines             | Approve when prompted                      |

**Bonus:** On first `rm` block in a git repo, `TRASH/` and `TRASH-FILES.md` are auto-added to the root `.gitignore` (covers entire repo).

## Configuration

Optional. Create `~/.claude/plugins/safety-hooks-config.yaml` for global defaults, or `.claude/plugins/safety-hooks-config.yaml` for project overrides.

```yaml
# Enable/disable hooks (all true by default)
enabled_hooks:
  rm_block: true
  git_add_block: true
  git_commit_ask: true
  env_protection: true
  file_length_limit: true

# Customize settings
file_length_limit:
  max_lines: 10000

rm_block:
  trash_dir: "TRASH"
  log_file: "TRASH-FILES.md"

git_add_block:
  allow_wildcards: false
  allow_dot_add: false
```

## FAQ

**Q: How do I disable a specific hook?**
A: Set `enabled_hooks.{hook_name}: false` in your config.

**Q: Can I still use `rm` if needed?**
A: Disable `rm_block` in your project config, or use `mv` to move files to TRASH.

**Q: Does this catch all git mistakes?**
A: No—only the most common dangerous patterns. Always review git commands.

## Credits

Inspired by [safety-hooks](https://github.com/pchalasani/claude-code-tools/tree/main/plugins/safety-hooks) by [Prudhvi Chalasani](https://github.com/pchalasani).

## License

MIT
