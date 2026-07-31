# 13 — Round-trip fidelity specs (P1)

**Status:** PARTIAL

## Gaps
- `spec/round_trip_spec.rb:47-48` asserts only that the output is a String
  containing `digitalCalibrationCertificate`. There is no canonical
  comparison, despite the goal above.
- The `fixture_globs` list omits `dsi_examples/**/*.xml`, so no D-SI example
  is round-tripped — even though the file comment at line 10 says otherwise.
- No per-class `spec/dcc/model/{element}_spec.rb` files exist.

## Goal
Lossless round-trip on every PTB fixture: parse → serialize → canonically compare with the original.

## Files
- `spec/support/canon_matcher.rb` — `be_canonical_xml_equivalent_to(expected)` matcher built on Canon gem.
- `spec/round_trip_spec.rb` — auto-discovers `spec/fixtures/**/*.{xml,dcc}` and parametrizes a round-trip example per file.
- Per-class spec under `spec/dcc/model/{element}_spec.rb` — one synthetic snippet per type, focused assertions.

## Design notes
- Use `Canon::Config` to ignore comments, structural whitespace, attribute order.
- Tag flaky/skipped fixtures in a `KNOWN_ISSUES` constant with reason and link to bug.
- Pre-Phase-13: any non-round-tripping fixture becomes a TODO for the relevant wrapper class.

## Dependencies
- 12.

## Verification
- `bundle exec rspec spec/round_trip_spec.rb` passes against all 50+ PTB + DCC + D-SI examples.
