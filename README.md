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

## Contributing

See [MARKETPLACE.md](./MARKETPLACE.md) for guidelines on creating and submitting plugins.

## License

MIT

Each plugin may have its own license. Refer to individual plugin directories for details.
