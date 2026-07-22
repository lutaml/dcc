# 35 — Documentation (P3)

**Status:** COMPLETED

## Goal
Polished documentation for users and contributors: README, examples, YARD docs, getting-started guide.

## Files
- `README.adoc` — quickstart, feature overview, install instructions (already scaffolded; expand with realistic examples).
- `docs/getting-started.adoc` — 5-minute tutorial: parse, validate, extract quantities, sign.
- `docs/cli-reference.adoc` — every CLI command with flags and examples.
- `docs/schema-versions.adoc` — supported versions, differences, migration paths.
- `docs/api/` — YARD docs (`*.rb` files have `# @!method` annotations).
- `examples/` — 5-10 runnable scripts: `parse_and_inspect.rb`, `validate_batch.rb`, `convert_to_json.rb`, `build_minimal_dcc.rb`, `sign_with_xmldsig.rb`, `migrate_v2_to_v3.rb`, `diff_two_dccs.rb`, `extract_and_evaluate_formula.rb`, `streaming_processor.rb`.

## Design notes
- All docs in AsciiDoc (consistent with lutaml ecosystem).
- Examples are executable specs — each is wrapped in a RSpec doctest.

## Dependencies
- All prior phases (docs reference everything).

## Verification
- `bundle exec yard doc` produces clean HTML.
- Each example in `examples/` runs end-to-end without error on a PTB fixture.
