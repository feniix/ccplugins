# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Claude plugin marketplace - a catalog of plugins distributed through Claude Code's plugin system. Users add this marketplace to discover and install plugins.

## Marketplace Architecture

This repository is not a traditional code project - it's a **manifest registry**. The core structure:

```
.claude-plugin/marketplace.json    # Marketplace manifest (required)
plugins/                           # Plugin directories
├── plugin-name-1/
│   ├── .claude-plugin/plugin.json # Plugin manifest
│   ├── commands/                   # Slash commands (.md files)
│   ├── agents/                     # Subagent definitions
│   ├── skills/                     # Agent skills (SKILL.md)
│   └── README.md
└── plugin-name-2/
```

### Two-Level Manifest System

1. **Marketplace manifest** (`.claude-plugin/marketplace.json`):
   - Lists all plugins in the marketplace
   - Each entry has `name`, `description`, `version`, `source` path
   - `source` is relative to marketplace root (e.g., `./plugins/hello-world`)

2. **Plugin manifests** (each plugin's `.claude-plugin/plugin.json`):
   - Defines individual plugin metadata
   - Required field: `name` (kebab-case)
   - Optional: `version`, `description`, `author`, `license`, `keywords`

### Plugin Components

- **Commands** (`commands/*.md`): Markdown files with YAML frontmatter. The `description` in frontmatter becomes the command help text. Filename (minus .md) becomes the slash command name.
- **Agents** (`agents/*.md`): Specialized subagents Claude can invoke
- **Skills** (`skills/*/SKILL.md`): Model-invoked capabilities
- **Hooks** (`hooks/hooks.json`): Event-driven automation
- **MCP Servers** (`.mcp.json`): External tool integrations

## Adding a New Plugin

```bash
# 1. Create plugin directory
mkdir -p plugins/new-plugin/.claude-plugin

# 2. Create plugin manifest
cat > plugins/new-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "new-plugin",
  "version": "1.0.0",
  "description": "Brief description"
}
EOF

# 3. Add to marketplace manifest
# Edit .claude-plugin/marketplace.json, append to plugins array:
# {"name": "new-plugin", "source": "./plugins/new-plugin", ...}
```

## Testing Plugins Locally

```bash
# Add the marketplace (from repo root)
claude
/plugin marketplace add .

# Install a plugin
/plugin install plugin-name@claude-plugins

# Test commands
/your-command
```

No build process, npm install, or compilation is required. Plugins are interpreted directly from source files.

## Important Constraints

- **All paths in manifests must be relative** and start with `./`
- **Plugin names must be kebab-case** (lowercase, hyphens only)
- **Commands are markdown files** - the content is a prompt that Claude executes
- **No TypeScript/JavaScript compilation** - this is a declarative plugin system

## Documentation

See `MARKETPLACE.md` for contributor guidelines and plugin creation instructions.
