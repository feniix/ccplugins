#!/usr/bin/env python3
"""Bump version for a plugin in the ccplugins marketplace.

Updates both the marketplace.json manifest and the plugin's own plugin.json.
"""

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Version:
    """Semantic version."""

    major: int
    minor: int
    patch: int

    def __str__(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"

    @classmethod
    def parse(cls, version: str) -> "Version":
        """Parse a version string."""
        match = re.match(r"(\d+)\.(\d+)\.(\d+)", version)
        if not match:
            raise ValueError(f"Invalid version format: {version}")
        return cls(int(match.group(1)), int(match.group(2)), int(match.group(3)))

    def bump(self, part: str) -> "Version":
        """Bump a version part."""
        if part == "major":
            return Version(self.major + 1, 0, 0)
        if part == "minor":
            return Version(self.major, self.minor + 1, 0)
        if part == "patch":
            return Version(self.major, self.minor, self.patch + 1)
        raise ValueError(f"Invalid version part: {part}")


def find_plugin_dir(plugin_name: str, repo_root: Path) -> Path:
    """Find the plugin directory."""
    plugin_dir = repo_root / "plugins" / plugin_name
    if not plugin_dir.exists():
        raise ValueError(f"Plugin directory not found: {plugin_dir}")
    return plugin_dir


def load_json(path: Path) -> dict:
    """Load and parse a JSON file."""
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")
    with path.open() as f:
        return json.load(f)


def save_json(path: Path, data: dict) -> None:
    """Save data to a JSON file with pretty formatting."""
    with path.open("w") as f:
        json.dump(data, f, indent=2, sort_keys=False)
        f.write("\n")


def get_current_version(plugin_dir: Path, plugin_name: str) -> Version:
    """Get current version from plugin.json."""
    plugin_json = plugin_dir / ".claude-plugin" / "plugin.json"
    data = load_json(plugin_json)
    version_str = data.get("version")
    if not version_str:
        raise ValueError(f"No version found in {plugin_json}")
    return Version.parse(version_str)


def update_plugin_manifest(plugin_dir: Path, new_version: Version) -> None:
    """Update the plugin's plugin.json."""
    plugin_json = plugin_dir / ".claude-plugin" / "plugin.json"
    data = load_json(plugin_json)
    data["version"] = str(new_version)
    save_json(plugin_json, data)
    print(f"Updated {plugin_json.relative_to(Path.cwd())} -> {new_version}")


def update_marketplace_manifest(repo_root: Path, plugin_name: str, new_version: Version) -> None:
    """Update the marketplace.json."""
    marketplace_json = repo_root / ".claude-plugin" / "marketplace.json"
    data = load_json(marketplace_json)

    # Find the plugin in the plugins array
    for plugin in data.get("plugins", []):
        if plugin.get("name") == plugin_name:
            plugin["version"] = str(new_version)
            save_json(marketplace_json, data)
            print(f"Updated {marketplace_json.relative_to(Path.cwd())} -> {new_version}")
            return

    raise ValueError(f"Plugin '{plugin_name}' not found in marketplace.json")


def list_plugins(repo_root: Path) -> None:
    """List all available plugins and their versions."""
    marketplace_json = repo_root / ".claude-plugin" / "marketplace.json"
    data = load_json(marketplace_json)

    print("Available plugins:")
    for plugin in data.get("plugins", []):
        name = plugin.get("name", "unknown")
        version = plugin.get("version", "unknown")
        print(f"  {name}: {version}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Bump version for a plugin in the ccplugins marketplace")
    parser.add_argument(
        "plugin",
        nargs="?",
        help="Plugin name (kebab-case). Use --list to see available plugins.",
    )
    parser.add_argument(
        "version",
        nargs="?",
        help='New version (e.g., "1.2.3") or bump type (major|minor|patch)',
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all available plugins and their versions",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without making changes",
    )

    args = parser.parse_args()

    repo_root = Path(__file__).parent.parent

    if args.list:
        list_plugins(repo_root)
        return

    if not args.plugin or not args.version:
        parser.error("plugin and version are required (or use --list)")

    plugin_dir = find_plugin_dir(args.plugin, repo_root)
    current_version = get_current_version(plugin_dir, args.plugin)

    # Determine new version
    if args.version in ("major", "minor", "patch"):
        new_version = current_version.bump(args.version)
    else:
        new_version = Version.parse(args.version)

    print(f"Bumping {args.plugin}: {current_version} -> {new_version}")

    if args.dry_run:
        print("(dry run, no changes made)")
        return

    update_plugin_manifest(plugin_dir, new_version)
    update_marketplace_manifest(repo_root, args.plugin, new_version)
    print("Version bump complete!")


if __name__ == "__main__":
    main()
