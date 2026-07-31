# 23 — Output models with format transforms (P2)

**Status:** PARTIAL

## Gaps
- `lib/dcc/output.rb` does not exist; the shared concern was never written.
- Five result models define `to_json`/`to_yaml` by hand. `Dcc::Extract::File`
  defines `to_s` only, so the verification below is false for it.

## Goal
Establish the pattern: every command/service returns a model object that responds to `to_s` (human-readable), `to_json` (machine), `to_yaml` (Ruby). The CLI picks the formatter based on `--format`.

## Files
- `lib/dcc/output.rb` — shared concern `Dcc::Output` that provides default `to_json` / `to_yaml` based on `to_h` (lutaml-model-generated). Models opt in via `include Dcc::Output`.
- Update `Dcc::Validate::Result`, `Dcc::Convert::Result`, `Dcc::Signature::Result`, `Dcc::Inspect::Report`, `Dcc::Diff::Result`, `Dcc::Extract::File` to include the concern.

## Design notes
- No hand-rolled `to_h`/`from_h` — use lutaml-model's framework-provided serialization (per global rule).
- `to_s` defaults to pretty-printed inspection; specific models override for tty-table formatting.

## Dependencies
- 14-19 (need the result models first).

## Verification
- Every result model `respond_to?(:to_s, :to_json, :to_yaml)` is true.
