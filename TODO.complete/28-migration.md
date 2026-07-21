# 28 — Version migration (P2)

**Status:** PENDING

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
