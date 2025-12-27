# Development Tools

## Version Bumping Script

Location: `scripts/bump_version.py`

Updates plugin versions across both manifest files atomically:

- `.claude-plugin/marketplace.json`
- `plugins/{name}/.claude-plugin/plugin.json`

### Usage

```bash
# List plugins
python3 scripts/bump_version.py --list

# Semantic version bumps
python3 scripts/bump_version.py <plugin> patch   # 0.2.0 -> 0.2.1
python3 scripts/bump_version.py <plugin> minor   # 0.2.0 -> 0.3.0
python3 scripts/bump_version.py <plugin> major   # 0.2.0 -> 1.0.0

# Explicit version
python3 scripts/bump_version.py <plugin> 1.0.0

# Dry run
python3 scripts/bump_version.py <plugin> patch --dry-run
```

### Key Points

- Always use this script—never edit version strings manually
- Both manifests must stay in sync
- Script validates plugin exists before modifying
- JSON files are pretty-printed with 2-space indent
