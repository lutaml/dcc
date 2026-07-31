# 30 — Quantity pretty-printing (P2)

**Status:** PARTIAL

## Gaps
- The documented output is wrong. For `value: 42.0, uncertainty: 0.05,
  unit: "\kelvin"` the formatter returns `42.0(05) kelvin` (short),
  `42.0 ± 0.05 kelvin` (long) and `\qty{42.0 +- 0.05}{\kelvin}` (latex) —
  not `42.00(5) K`. The value is not padded to the uncertainty's precision,
  the compact uncertainty keeps its leading zero, and the unit is not
  rendered as a symbol.
- `lib/dcc/quantity_format/formatter.rb` never requires `bigdecimal`, so
  `Formatter.new` raises `NoMethodError` in isolation. The suite passes only
  because `lib/dcc/validate/schematron/profile.rb` requires it first.

## Goal
SmartCom-style human-readable formatting of D-SI quantities with proper significant digits and unit composition.

## Files
- `lib/dcc/quantity_format.rb` — autoloads.
- `lib/dcc/quantity_format/formatter.rb` — `Dcc::QuantityFormat::Formatter.new(value:, uncertainty:, unit:)`
  with `#to_short`, `#to_long` and `#to_latex`.
- Templates for each format style.

## Design notes
- Significant digits derived from uncertainty (PTB convention: 2 sig digits in uncertainty, value rounded to matching precision).
- LaTeX output uses siunitx notation: `\qty{42.00 +- 0.05}{\kelvin}`.
- Short output: `42.00(5) K` (compact uncertainty notation).

## Dependencies
- 10.

## Verification
- Spec covers all three formats on representative inputs.
