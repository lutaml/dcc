# 30 — Quantity pretty-printing (P2)

**Status:** PENDING

## Goal
SmartCom-style human-readable formatting of D-SI quantities with proper significant digits and unit composition.

## Files
- `lib/dcc/quantity_format.rb` — autoloads.
- `lib/dcc/quantity_format/formatter.rb` — `Dcc::QuantityFormat::Formatter.call(quantity, format: :short|:long|:latex)`.
- Templates for each format style.

## Design notes
- Significant digits derived from uncertainty (PTB convention: 2 sig digits in uncertainty, value rounded to matching precision).
- LaTeX output uses siunitx notation: `\qty{42.00 +- 0.05}{\kelvin}`.
- Short output: `42.00(5) K` (compact uncertainty notation).

## Dependencies
- 10.

## Verification
- Spec covers all three formats on representative inputs.
