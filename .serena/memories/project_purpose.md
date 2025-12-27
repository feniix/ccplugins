# Project Purpose

## Overview
This is a **Claude Plugin Marketplace** - a catalog of plugins distributed through Claude Code's plugin system. Users add this marketplace to discover and install plugins.

## Architecture
This is a **manifest registry**, not a traditional code project. The structure:

- `.claude-plugin/marketplace.json` - Marketplace manifest (required)
- `plugins/` - Plugin directories
  - Each plugin has `.claude-plugin/plugin.json` (plugin manifest)
  - `commands/` - Slash commands (.md files with YAML frontmatter)
  - `agents/` - Subagent definitions
  - `skills/` - Agent skills (SKILL.md)
  - `hooks/` - Event-driven automation

## Key Plugin: safety-hooks
Blocks or requires approval for dangerous commands:
- Blocks `rm` commands (redirects to TRASH directory)
- Protects `.env` files from read/write access
- Git operation safeguards (git add wildcards, git commit approval, git checkout protection)
- File size limits (asks approval when source files exceed 10,000 lines)

## Configuration
Hooks are configured via YAML files (not source code modification):
- Global: `~/.claude/plugins/safety-hooks-config.yaml`
- Project: `.claude/plugins/safety-hooks-config.yaml`
- Configs merge: defaults → global → project
