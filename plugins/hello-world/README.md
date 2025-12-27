# Hello World Plugin

A simple "Hello World" plugin for Claude Code that demonstrates the basic plugin structure.

## Installation

Once this marketplace is added, install the plugin:

```
/plugin install hello-world@claude-plugins
```

## Usage

After installation, use the command:

```
/hello [name]
```

### Examples

```bash
/hello              # Outputs: Hello, World!
/hello Claude       # Outputs: Hello, Claude!
/hello Developer    # Outputs: Hello, Developer!
```

## Plugin Structure

This plugin demonstrates the minimal structure required:

```
hello-world/
├── .claude-plugin/
│   └── plugin.json      # Plugin manifest
├── commands/
│   └── hello.md         # Command definition with frontmatter
└── README.md            # This file
```

## Development

Use this plugin as a template for creating your own plugins:

1. Copy the `hello-world` directory
1. Rename it to your plugin name (kebab-case)
1. Update `plugin.json` with your plugin's metadata
1. Modify or add commands in the `commands/` directory
1. Add your plugin to the marketplace `.claude-plugin/marketplace.json`

## License

MIT
