# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/math"

module Dcc
  # `Dcc::QuantityMath` provides BigDecimal-based arithmetic on D-SI
  # quantities with proper uncertainty propagation.
  #
  # `Real` is scalar: RSS (root-sum-square) for addition and subtraction,
  # fractional for multiplication and division. `Matrix` is multivariate and
  # carries a full covariance matrix, propagating by `C_y = J C J^T`.
  # `Complex` is a Cartesian complex quantity built on a two-element
  # `Matrix`, so the correlation between its real and imaginary parts
  # survives every operation.
  module QuantityMath
    # Significant digits requested when taking the square root of a
    # BigDecimal variance. Well past double precision; metrology
    # uncertainties never carry this many digits. Ordinary arithmetic
    # follows the caller's ambient BigDecimal context.
    SQRT_PRECISION = 30

    autoload :Quantity, "dcc/quantity_math/quantity"
    autoload :Real, "dcc/quantity_math/real"
    autoload :Matrix, "dcc/quantity_math/matrix"
    autoload :Complex, "dcc/quantity_math/complex"

    # Runs `block` with an unlimited BigDecimal precision, restoring the
    # caller's `BigDecimal.limit` on the way out (including when the block
    # raises). Everything feeding a covariance matrix goes through here: a
    # rounded result is no longer exactly symmetric, and `Matrix`'s
    # validation would reject our own output.
    #
    # @return [Object] whatever `block` returns
    def self.exact_covariance
      BigDecimal.save_limit do
        BigDecimal.limit(0)
        yield
      end
    end
  end
end
