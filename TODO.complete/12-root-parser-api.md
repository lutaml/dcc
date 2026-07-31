# 12 — Root parser public API (P1)

**Status:** COMPLETED

## Goal
Finalize the public parse entry points: `Dcc.parse`, `Dcc::V2.parse`, `Dcc::V3.parse`. Verify auto-version detection works end-to-end.

## Files
- `lib/dcc.rb` already defines `Dcc.parse(input, version:, context:, register:)`, `parser_for(version)`, `detect_version(input)`.
- No `spec/dcc/parse_spec.rb` was created. `spec/dcc_spec.rb` covers
  `parser_for`, `detect_version` and input handling; the `Dcc.parse`
  examples live in `spec/ptb_fixtures_spec.rb` and `spec/round_trip_spec.rb`.
  Between them they cover:
  - Auto-detect from `schemaVersion="3.3.0"` → V3.
  - Auto-detect from `schemaVersion="2.3.0"` → V2.
  - Explicit `version: 2` / `version: 3`.
  - (Not covered: `context: :dcc_v3_4` — that context does not exist. See phase 09.)
  - Error on unknown version.

## Design notes
- `detect_version` reads the first `schemaVersion="X.Y.Z"` attribute via regex; defaults to 3 if not found.
- IO inputs are read once on entry (no double-read).

## Dependencies
- 08, 09, 11.

## Verification
- `Dcc.parse(File.read("spec/fixtures/ptb/valid.xml")).class` → `Dcc::V3::DigitalCalibrationCertificate`.
- `Dcc.parse(File.read("spec/fixtures/dcc_examples/example.xml")).class` → `Dcc::V2::DigitalCalibrationCertificate` (it's a 2.3.0 doc).
