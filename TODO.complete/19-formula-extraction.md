# 19 — Formula extraction and evaluation (P1)

**Status:** PENDING

## Goal
Extract MathML `<ml:apply>` formula trees from `dcc:formula`, build a Ruby AST, and evaluate numerically with BigDecimal precision.

## Files
- `lib/dcc/extract/formula.rb` — autoloads + entry point `Dcc::Extract::Formula.call(dcc)` returning `[Dcc::Extract::Formula::Ast]`.
- `lib/dcc/extract/formula/parser.rb` — recursive-descent MathML content-MathML parser.
- `lib/dcc/extract/formula/ast.rb` — AST node types (`Number`, `Variable`, `Apply`, `BoundVariable`, `Constant`).
- `lib/dcc/extract/formula/evaluator.rb` — BigDecimal evaluator with `+`, `-`, `*`, `/`, `sqrt`, `**`, `exp`, `ln`, `sin`, `cos`, `tan`, `log`, `abs`.
- `lib/dcc/extract/formula/quantity.rb` — value object `(BigDecimal value, String unit, BigDecimal|nil uncertainty)`.

## Design notes
- PTB's Callendar-Van-Dusen example (`valid_formula.xml`) is the integration test.
- Numeric evaluation only — symbolic simplification is out of scope (per plan).
- BigDecimal `sqrt` uses Newton's method (or `bigdecimal/math`).
- Variables can be scalar or list; evaluator supports element-wise operations.

## Dependencies
- 12.

## Verification
- Parse `valid_formula.xml`, evaluate the formula at T=42 (single value), match PTB's `dcclib extract formulae -v T=42` output to 6 significant figures.
