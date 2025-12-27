# Claude Plugins Marketplace

A collection of Claude Code plugins for extending functionality.

## Adding the Marketplace

To use this marketplace, add it to your Claude Code configuration:

### Local Development

```bash
cd /path/to/your-project
claude
/plugin marketplace add /path/to/claude-plugins
```

### From GitHub

Once published, add via:

```bash
/plugin marketplace add your-username/claude-plugins
```

## Installing Plugins

List available plugins:

```bash
/plugin marketplace list claude-plugins
```

Install a plugin:

```bash
/plugin install plugin-name@claude-plugins
```

## Available Plugins

| Plugin                                  | Description                                                    | Version |
| --------------------------------------- | -------------------------------------------------------------- | ------- |
| [hello-world](./plugins/hello-world/)   | A simple hello world command plugin                            | 1.0.0   |
| [safety-hooks](./plugins/safety-hooks/) | Safety hooks for dangerous commands (rm, git, .env, file size) | 0.1.0   |

## Creating a New Plugin

### 1. Create the Plugin Directory

```bash
mkdir -p plugins/your-plugin/.claude-plugin
mkdir -p plugins/your-plugin/commands
```

### 2. Create the Plugin Manifest

Create `plugins/your-plugin/.claude-plugin/plugin.json`:

```json
{
  "name": "your-plugin",
  "version": "1.0.0",
  "description": "Brief description of your plugin",
  "author": {
    "name": "Your Name"
  },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

### 3. Create Commands

Add markdown files in `plugins/your-plugin/commands/`:

```markdown
---
description: Brief command description
argument-hint: [optional-arg]
---

# Command Name

Detailed instructions for Claude on how to execute this command.

## Instructions

1. Step one
2. Step two
3. Step three
```

### 4. Register in Marketplace

Add your plugin to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "description": "Brief description",
      "version": "1.0.0",
      "source": "./plugins/your-plugin",
      "category": "utilities",
      "tags": ["tag1", "tag2"],
      "keywords": ["keyword1", "keyword2"]
    }
  ]
}
```

### 5. Test Your Plugin

```bash
# Reload the marketplace
/plugin marketplace reload claude-plugins

# Install your plugin
/plugin install your-plugin@claude-plugins

# Test the command
/your-command
```

## Plugin Structure

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json       # Required: plugin manifest
    ├── commands/              # Optional: slash commands
    │   └── command-name.md
    ├── agents/                # Optional: subagent definitions
    ├── skills/                # Optional: agent skills
    ├── hooks/                 # Optional: event hooks
    ├── .mcp.json             # Optional: MCP server config
    └── README.md              # Recommended: documentation
```

## Naming Conventions

- **Plugin names**: Use kebab-case (e.g., `my-awesome-plugin`)
- **Commands**: Use kebab-case (e.g., `deploy-app.md` → `/deploy-app`)
- **Marketplace name**: Use kebab-case (e.g., `team-plugins`)

## Resources

- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins)
- [Plugin Reference](https://code.claude.com/docs/en/plugins-reference)
- [Slash Commands](https://code.claude.com/docs/en/slash-commands)
- [Agent Skills](https://code.claude.com/docs/en/skills)
- [Hooks](https://code.claude.com/docs/en/hooks)

## License

Each plugin may have its own license. Please refer to individual plugin directories for specific licensing information.
