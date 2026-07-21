# 17 — JSON converter (P1)

**Status:** PENDING

## Goal
Convert a parsed DCC into JSON. Two styles: `:ptb_compatible` (matches PTB `JSONConverter` output) and `:lutaml` (uses lutaml-model's JSON mapping DSL directly).

## Files
- `lib/dcc/convert.rb` — autoloads + base converter concern.
- `lib/dcc/convert/result.rb` — `Dcc::Convert::Result` model with `to_s`, `to_json`, `to_yaml`.
- `lib/dcc/convert/json.rb` — `Dcc::Convert::Json.call(dcc, style: :ptb_compatible)` returns a `Dcc::Convert::Result` whose `to_s` produces the JSON.

## Design notes
- `:ptb_compatible` matches PTB's `$`-prefix convention for attributes vs. elements.
- `:lutaml` uses the model's `to_json` directly.
- The output is a model object — never a raw String — so callers can re-format via `to_yaml`/`to_s`.

## Dependencies
- 12.

## Verification
- `Dcc::Convert::Json.call(dcc, style: :ptb_compatible).to_s` is structurally equivalent to PTB's output on the same input.
- Round-trip: `JSON.parse(json)` then walk the resulting hash matches `dcc.to_hash` shape.
