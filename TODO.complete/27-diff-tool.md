# 27 — DCC diff tool (P2)

**Status:** PENDING

## Goal
Structural diff of two DCCs — what items/quantities/results were added, removed, or modified.

## Files
- `lib/dcc/diff.rb` — autoloads.
- `lib/dcc/diff/result.rb` — `Dcc::Diff::Result` model with `changes` (Array), `to_s` (unified-diff style), `to_json`, `to_yaml`.
- `lib/dcc/diff/change.rb` — `Change` value object (`path`, `kind` ∈ {add, remove, change}, `before`, `after`).
- `lib/dcc/diff/comparator.rb` — recursive tree comparator with sensible equality rules (BigDecimal vs Float, language-tagged text).

## Design notes
- Identity keys: `uniqueIdentifier` for certificates, `id`/`refId` for elements, `name`+`refType` for quantities.
- Numeric tolerance configurable (default 1e-9).

## Dependencies
- 12.

## Verification
- Diff a fixture against itself → empty changes.
- Diff `valid.xml` vs a modified copy (one quantity value changed) → exactly one change record.
