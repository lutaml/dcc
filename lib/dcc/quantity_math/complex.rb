# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module QuantityMath
    # A complex quantity in Cartesian form, backed by a two-element `Matrix`:
    # element 0 is the real part, element 1 the imaginary part, and both
    # share one unit.
    #
    # The full 2x2 covariance is propagated through every operation, so
    # chaining stays correct. A product's real and imaginary parts are
    # correlated, and dropping that off-diagonal term understates the next
    # result — for `(z1 * z2) * z3` by a third in the worked case.
    #
    # `+` and `-` assume the two operands are statistically INDEPENDENT, so
    # `z - z` returns twice the covariance rather than zero.
    class Complex
      ONE = BigDecimal(1)
      private_constant :ONE

      # Significant digits kept for the division derivatives. They are the
      # only non-terminating arithmetic in the propagation path: Ruby's
      # `Complex#/` runs Smith's algorithm, whose internal `bim/bre` does not
      # terminate, so an unbounded derivative carries ~130 digits of which
      # only ~30 are meaningful. Those digits then multiply forward into
      # every downstream covariance.
      #
      # Bounding them here rather than rounding the covariance is deliberate.
      # Inside `QuantityMath.exact_covariance`, which sets
      # `BigDecimal.limit(0)`, multiplication and addition are exact, so
      # `J C J^T` over bounded derivatives stays exact — and therefore
      # exactly symmetric and exactly positive semi-definite. That exactness
      # comes from the zero limit, not from BigDecimal itself: under a
      # non-zero `BigDecimal.limit` both operations round. Moving any of this
      # arithmetic outside that block reintroduces the asymmetry the
      # covariance validation rejects. Rounding the covariance instead would
      # risk failing PSD validation on the exactly-singular matrices that a
      # component with no uncertainty produces.
      #
      # It happens to equal `SQRT_PRECISION`, but the two are independent:
      # that one sizes a square root of a variance, this one a derivative.
      # Changing either should not drag the other along.
      DERIVATIVE_PRECISION = 30

      attr_reader :matrix

      # @param matrix [Matrix] two elements sharing one unit
      def initialize(matrix:)
        ensure_complex_shape!(matrix)
        @matrix = matrix
      end

      # @param real [Real] real component
      # @param imag [Real] imaginary component, same unit as `real`
      # @param covariance [Array<Array>, nil] 2x2. Defaults to the diagonal
      #   built from each component's uncertainty; a component with no
      #   uncertainty contributes zero variance, i.e. is treated as exact.
      # @return [Complex]
      def self.cartesian(real:, imag:, covariance: nil)
        new(matrix: Matrix.new(values: [real.value, imag.value],
                               units: [real.unit, imag.unit],
                               covariance: covariance || diagonal(real, imag)))
      end

      def self.diagonal(real, imag)
        QuantityMath.exact_covariance do
          zero = BigDecimal(0)
          [[variance(real), zero], [zero, variance(imag)]]
        end
      end

      def self.variance(component)
        component.uncertain? ? component.uncertainty**2 : BigDecimal(0)
      end
      private_class_method :diagonal, :variance

      # @return [String, nil] siunitx expression shared by both components.
      def unit
        matrix.units.first
      end

      # @return [Real]
      def real
        matrix[0]
      end

      # @return [Real]
      def imag
        matrix[1]
      end

      # @return [Array<Array<BigDecimal>>] the 2x2 covariance.
      def covariance
        matrix.covariance
      end

      # Reads the variances directly rather than going through
      # `Matrix#uncertainties`: for the non-negative diagonal that validation
      # guarantees, `x.zero?` and `sqrt(x).zero?` agree, and this avoids two
      # 30-digit square roots to answer a zero test.
      #
      # @return [Boolean] whether either component carries uncertainty.
      def uncertain?
        covariance.each_with_index.any? { |row, i| !row[i].zero? }
      end

      # @return [::Complex] the value as a Ruby Complex of BigDecimals.
      def to_c
        ::Complex.rectangular(*matrix.values)
      end

      # Assumes independence from `other`.
      # @return [Complex]
      def +(other)
        Complex.new(matrix: matrix + other.matrix)
      end

      # Assumes independence from `other`.
      # @return [Complex]
      def -(other)
        Complex.new(matrix: matrix - other.matrix)
      end

      # @return [Complex]
      def *(other)
        combine(other,
                value: to_c * other.to_c,
                unit: compose_unit(unit, other.unit),
                d_self: other.to_c,
                d_other: to_c)
      end

      # The quotient VALUE follows the caller's ambient BigDecimal context,
      # like every other value here. Its DERIVATIVES feed the covariance, so
      # `1/z2` and `-z1/z2^2` are computed at full precision instead.
      #
      # @raise [ZeroDivisionError] when `other` is exactly 0 + 0i.
      # @return [Complex]
      def /(other)
        ensure_nonzero!(other)
        divisor = other.to_c
        d_self, d_other = division_derivatives(divisor)
        combine(other,
                value: to_c / divisor,
                unit: compose_unit(unit, inverse_unit(other.unit)),
                d_self: d_self, d_other: d_other)
      end

      def to_s
        re, im = matrix.values
        sign = im.negative? ? "-" : "+"
        suffix = unit ? " #{unit}" : ""
        "(#{measured(re, 0)}) #{sign} (#{measured(im.abs, 1)})i#{suffix}"
      end

      private

      # Renders one component, dropping the "± u" when its variance is zero.
      # `uncertain?` already treats an all-zero covariance as exact, so
      # printing "± 0.0" would have this class contradicting itself.
      def measured(value, index)
        variance = covariance[index][index]
        return value.to_s if variance.zero?

        "#{value} ± #{variance.sqrt(SQRT_PRECISION)}"
      end

      # dw/dz1 = 1/z2 and dw/dz2 = -z1/z2^2, both at full precision because
      # they feed the covariance.
      def division_derivatives(divisor)
        QuantityMath.exact_covariance do
          [bounded(ONE / divisor), bounded(-(to_c / divisor) / divisor)]
        end
      end

      # Trims a derivative to DERIVATIVE_PRECISION significant digits.
      def bounded(derivative)
        ::Complex.rectangular(
          derivative.real.div(ONE, DERIVATIVE_PRECISION),
          derivative.imaginary.div(ONE, DERIVATIVE_PRECISION),
        )
      end

      # Stacks self and `other` into one four-element quantity whose
      # covariance is block-diagonal (the operands are assumed independent of
      # each other, though each keeps its own internal correlation), then
      # propagates the 2x4 Jacobian.
      def combine(other, value:, unit:, d_self:, d_other:)
        Complex.new(matrix: stack(other).propagate(
          values: [value.real, value.imaginary],
          units: [unit, unit],
          jacobian: jacobian_for(d_self, d_other),
        ))
      end

      # `d_self` and `d_other` are the complex derivatives dw/dz1 and dw/dz2.
      # Multiplying by a complex number p has real Jacobian
      # [[Re p, -Im p], [Im p, Re p]]. The signs WITHIN each 2x2 rotation
      # block are load-bearing — unlike a diagonal model, they do not cancel
      # under J C J^T. Negating a whole block is invisible, because `stack`
      # always builds a block-diagonal C and each block contributes
      # `A C A^T`, which is invariant under `A -> -A`. That would stop
      # holding if correlated operands were ever supported.
      def jacobian_for(d_self, d_other)
        [[d_self.real, -d_self.imaginary, d_other.real, -d_other.imaginary],
         [d_self.imaginary, d_self.real, d_other.imaginary, d_other.real]]
      end

      def stack(other)
        Matrix.new(values: matrix.values + other.matrix.values,
                   units: matrix.units + other.matrix.units,
                   covariance: block_diagonal(covariance, other.covariance))
      end

      def block_diagonal(first, second)
        zeros = [BigDecimal(0), BigDecimal(0)]
        first.map { |row| row + zeros } + second.map { |row| zeros + row }
      end

      def ensure_complex_shape!(matrix)
        unless matrix.values.size == 2
          raise ::ArgumentError,
                "complex quantity needs 2 elements, got #{matrix.values.size}"
        end
        return if matrix.units.uniq.size == 1

        raise ::ArgumentError, "unit mismatch: #{matrix.units.inspect}"
      end

      def ensure_nonzero!(other)
        return unless other.to_c.zero?

        raise ::ZeroDivisionError, "divided by a zero complex quantity"
      end

      def compose_unit(left, right)
        return nil if left.nil? && right.nil?
        return left if right.nil?
        return right if left.nil?

        "#{left}\\cdot#{right}"
      end

      def inverse_unit(unit)
        return nil if unit.nil?

        "#{unit}^-1"
      end
    end
  end
end
