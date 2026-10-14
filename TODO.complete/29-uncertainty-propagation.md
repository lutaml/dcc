# 29 — Uncertainty propagation (P2)

**Status:** PARTIAL

## Gaps
- `Dcc::QuantityMath::Real` implements `+`, `-`, `*`, `/` and `**` only. The
  `sqrt` and comparison operators listed under Files are not defined.
- `Dcc::QuantityMath::Quantity` carries `(value, unit, uncertainty)`.
  `coverage_factor` and `coverage_probability` do not exist — passing either
  to the constructor raises `unknown keyword`.
- `Real` propagates uncertainty through `Math.sqrt(x.to_f)`
  (`lib/dcc/quantity_math/real.rb:79`, `:90`), so RSS and fractional results
  are capped at double precision rather than honouring the BigDecimal
  precision the design notes describe. `Complex` and `Matrix` do take exact
  BigDecimal square roots.

## Goal
BigDecimal-based arithmetic on D-SI quantities that propagates uncertainty via root-sum-square (RSS) for add/sub and fractional for mul/div.

## Files
- `lib/dcc/quantity_math.rb` — autoloads.
- `lib/dcc/quantity_math/quantity.rb` — value object `(BigDecimal value, SiUnit unit, uncertainty, coverage_factor, coverage_probability)`.
- `lib/dcc/quantity_math/real.rb` — `+`, `-`, `*`, `/`, `**`, `sqrt`, comparison operators.
- `lib/dcc/quantity_math/complex.rb` — complex quantity arithmetic (Cartesian).
- `lib/dcc/quantity_math/matrix.rb` — covariance-matrix-aware operations for multivariate.

## Design notes
- All math in BigDecimal; precision configurable via `BigDecimal.precision`.
- Unit consistency checked (raise on mismatch unless explicit conversion).
- Output: a new `Quantity` with propagated uncertainty.

## Dependencies
- 10.

## Verification
- `q1 + q1` where q1 has uncertainty u → result has uncertainty `u * sqrt(2)`.
- Spec covers all four basic operators + power.
