# 28 — Version migration (P2)

**Status:** PARTIAL

## Gaps
- `lib/dcc/migrate/v3_to_v3_4.rb` is absent, and there is no migration to
  v3.4.0-rc.2. That version is not bundled — `Schema::Version::DCC_ALL` stops
  at `3.3.0` and `resolve_dcc("3.4.0-rc.2")` raises `UnknownVersionError`.
- Only `2.3.0 → 3.3.0` has a real transform. `Route.supported_pairs` also
  lists `3.2.1 → 3.3.0`, which only rewrites `schemaVersion`; every other
  pair raises. DCC 2.1.0 and 2.1.1 import `dsi/v1.0.1.xsd`, whose
  targetNamespace is `https://intranet.ptb.de/...`, and nothing rewrites it,
  so those versions are refused rather than migrated.

## Goal
`Dcc.migrate(dcc, from:, to:)` upgrades or downgrades a DCC between schema versions, applying the necessary field renames and D-SI version transitions.

## Files
- `lib/dcc/migrate.rb` — autoloads + entry point.
- `lib/dcc/migrate/route.rb` — registry of supported `(from, to)` migrations.
- `lib/dcc/migrate/v2_to_v3.rb` — v2 → v3 migration (adds empty `refId`/`refType`, upgrades D-SI v1 → v2 quantity elements).
- `lib/dcc/migrate/v3_to_v3_4.rb` — minor-version migration to v3.4.0-rc.2.

## Design notes
- Migrations are one-way; reverse migrations lose information and warn.
- Always return a fresh object (the input is never mutated).

## Dependencies
- 08, 09.

## Verification
- Migrate a v2 fixture to v3, re-validate against v3 XSD, result `ok?` is true.
