# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository hosts Claude plugins - integrations that extend Claude's capabilities with custom tools, data sources, or domain-specific knowledge. Plugins are distributed and installed by Claude Code users.

## Getting Started

### Initial Setup

Before starting work on plugins, initialize the development environment:

```bash
npm install
```

### Common Commands

**Development**
- `npm run build` - Build all plugins
- `npm run dev` - Run in development mode with watch
- `npm test` - Run all tests
- `npm run test -- path/to/test.ts` - Run a specific test
- `npm run lint` - Lint all code
- `npm run lint:fix` - Fix linting issues

**Plugin Distribution**
- `npm run publish` - Publish plugins to registry
- `npm run validate` - Validate plugin manifests and configurations

## Architecture Overview

### Plugin Structure

Claude plugins follow a standardized structure to ensure compatibility with Claude Code. Each plugin should:

1. **Have a manifest** (`plugin.json` or similar) that declares:
   - Plugin name and version
   - Available tools/capabilities
   - Configuration schema
   - Entry point

2. **Export implementation** - The actual plugin code that implements declared capabilities

3. **Include documentation** - README explaining what the plugin does and how to use it

### Key Architectural Patterns

**Plugin Interface**: Plugins implement a standard interface to work with Claude Code's plugin system. Check existing plugins for the interface contract.

**Configuration Management**: Plugins accept user configuration through standardized schema. Configuration is validated against the manifest schema before runtime.

**Error Handling**: Plugins should propagate errors clearly to Claude Code so users understand what went wrong and can fix configuration or usage issues.

### Directory Organization

Organize plugins in top-level directories by functionality or domain. Each plugin directory should be self-contained and independently distributable.

## Development Workflow

1. Create a new plugin directory with manifest and implementation
2. Write tests for plugin functionality
3. Run `npm test` to ensure all tests pass
4. Run `npm run lint` and `npm run lint:fix` to maintain code quality
5. Build with `npm run build` to validate the plugin
6. Update documentation to reflect plugin capabilities

## Testing

Tests should cover:
- Plugin initialization and configuration validation
- All exported tools/capabilities
- Error scenarios and edge cases
- Integration with Claude Code when applicable

Run tests frequently during development - use `npm run test -- path/to/test.ts` for fast iteration on specific tests.

## Build and Distribution

Plugins are built into distributable artifacts. The build process:
- Validates plugin manifests
- Bundles plugin code and dependencies
- Generates distribution artifacts
- Validates output for compatibility

Always run `npm run build` before considering a plugin ready for use.
