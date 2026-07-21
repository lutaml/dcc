# 25 — YAML/CSV/HTML converters (P2)

**Status:** PENDING

## Goal
Additional output formats beyond JSON: YAML (Ruby-friendly), CSV (tabular quantity export), HTML (human-readable report).

## Files
- `lib/dcc/convert/yaml.rb` — `Dcc::Convert::Yaml.call(dcc)` returns `Result` whose `to_s` produces YAML.
- `lib/dcc/convert/csv.rb` — flattens all measurement results into a CSV with columns: result_name, quantity_name, value, unit, uncertainty, k_factor.
- `lib/dcc/convert/html.rb` — collapsible tree-view HTML report with language selector.

## Design notes
- Each converter returns a `Dcc::Convert::Result` model — never a raw String.
- HTML converter uses ERB templates from `lib/dcc/convert/templates/`.

## Dependencies
- 17.

## Verification
- `Dcc::Convert::Csv.call(dcc).to_s` first row is the header; subsequent rows match the quantity list.
- HTML output renders in a browser without errors.
