# 34 — Plugin system (P3)

**Status:** COMPLETED

## Goal
Registry-based plugin system for custom validators, converters, and CLI commands.

## Files
- `lib/dcc/plugin.rb` — autoloads + `Dcc::Plugin.register(name, plugin)`, `Dcc::Plugin.all`.
- `lib/dcc/plugin/base.rb` — base module plugins include.

## Design notes
- Plugins can register:
  - `Dcc::Validate` rules (added to the active profile).
  - `Dcc::Convert` format handlers (new format names).
  - `Dcc::Cli` Thor subcommands.
- Loaded via `Dcc.load_plugins` or auto-discovered from `dcc/*` gem prefix.

## Dependencies
- 14-19.

## Verification
- Register a custom validator plugin, run validation, assert the new rule fires on a crafted fixture.
