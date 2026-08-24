# 34 — Plugin system (P3)

**Status:** PARTIAL

## Gaps
- There is no gem-prefix auto-discovery. `Dcc.load_plugins` loads plugins by
  explicit name; nothing scans installed gems for the `dcc/*` prefix.
- Only validators are wired end to end. `Dcc::Plugin::Base` declares
  `register_validator` and nothing else, and neither `Dcc::Convert` nor
  `Dcc::Cli` reads `Dcc::Plugin.all`, so a converter or CLI subcommand can
  be neither declared nor consumed. `Dcc::Validate` does read the registry,
  via `Dcc::Validate::Schematron::Profile`.

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
