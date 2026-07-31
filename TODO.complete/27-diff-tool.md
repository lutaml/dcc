# 27 — DCC diff tool (P2)

**Status:** COMPLETED

## Goal
Structural diff of two DCCs — what items/quantities/results were added, removed, or modified.

## Files
- `lib/dcc/diff.rb` — autoloads.
- `lib/dcc/diff/result.rb` — `Dcc::Diff::Result` model with `changes` (Array), `to_s` (unified-diff style), `to_json`, `to_yaml`.
- `lib/dcc/diff/change.rb` — `Change` value object (`path`, `kind` ∈ {add, remove, change}, `before`, `after`).
- No `lib/dcc/diff/comparator.rb` was created; the recursive comparator is `Dcc::Diff.collect_differences` in `lib/dcc/diff.rb`.

## Design notes
- Neither identity keys nor a configurable numeric tolerance is implemented.
  The comparator walks attributes recursively and compares collections positionally.

## Dependencies
- 12.

## Verification
- Diff a fixture against itself → empty changes.
- Diff `valid.xml` vs a modified copy (one quantity value changed) → exactly one change record.
