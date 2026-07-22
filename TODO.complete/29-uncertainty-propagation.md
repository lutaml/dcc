# 29 — Uncertainty propagation (P2)

**Status:** COMPLETED

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
