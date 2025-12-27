# ccplugins

> A Claude Code plugin marketplace.

An open marketplace of plugins to extend Claude Code's capabilities.

## Quick Start

```bash
# Add the marketplace
/plugin marketplace add feniix/ccplugins

# List available plugins
/plugin marketplace list ccplugins

# Install a plugin
/plugin install safety-hooks@ccplugins
```

## Available Plugins

| Plugin                                  | Description                                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [safety-hooks](./plugins/safety-hooks/) | Guards against accidental data loss—blocks `rm`, protects `.env`, enforces safer git workflows |

## Development

### Version Bumping

Use the version bump script to update plugin versions across both manifests:

```bash
# List available plugins
python3 scripts/bump_version.py --list

# Bump patch version (0.2.0 -> 0.2.1)
python3 scripts/bump_version.py safety-hooks patch

# Bump minor version (0.2.0 -> 0.3.0)
python3 scripts/bump_version.py safety-hooks minor

# Bump major version (0.2.0 -> 1.0.0)
python3 scripts/bump_version.py safety-hooks major

# Set specific version explicitly
python3 scripts/bump_version.py safety-hooks 1.0.0

# Preview changes without writing
python3 scripts/bump_version.py safety-hooks patch --dry-run
```

The script updates both:

- `.claude-plugin/marketplace.json`
- `plugins/{name}/.claude-plugin/plugin.json`

## Contributing

See [MARKETPLACE.md](./MARKETPLACE.md) for guidelines on creating and submitting plugins.

## License

MIT

Each plugin may have its own license. Refer to individual plugin directories for details.
