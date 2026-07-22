# 38 — Convert pending specs to real passing specs (P1)

**Status:** PENDING

## Goal
5 specs use `pending`/`skip`. Convert each to a real, passing spec or
remove it if the feature truly isn't implemented.

## Files / specs to address
- `spec/dcc_spec.rb:15` — `Dcc.parser_for raises UnknownVersionError`
  (was: pending "autoload of Dcc::Error requires Dcc::V2/V3 to be loaded first")
- `spec/dcc/validate/schematron_spec.rb:20` — `flags invalid documents`
- `spec/dcc/validate/schematron_spec.rb:28` — `produces issues with codes`
- `spec/dcc/extract/formula_spec.rb:12` — `extracts at least one formula`
- `spec/dcc/streaming/reader_spec.rb:9` — `streams measurementResult elements`

## Approach
For each pending spec, either:
1. Fix the underlying feature so the spec passes naturally, or
2. Rewrite the spec to assert on what actually works, or
3. Remove the spec if it duplicates coverage elsewhere.

## Verification
- `bundle exec rspec` reports 0 pendings, 0 failures
