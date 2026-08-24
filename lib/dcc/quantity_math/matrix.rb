# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module QuantityMath
    # A multivariate quantity: a vector of values with per-element units and
    # a full covariance matrix. Propagation follows the GUM Supplement 2 law
    # `C_y = J C J^T`, so correlation between elements survives.
    #
    # `+` and `-` assume the two operands are statistically INDEPENDENT: the
    # covariance matrices are summed with no cross term, so `x - x` returns
    # `2C` rather than zero. Model correlated quantities as elements of one
    # `Matrix` and combine them with `propagate`.
    class Matrix
      attr_reader :values, :units, :covariance

      # @param values [Array<BigDecimal, Numeric, String>]
      # @param units [Array<String, nil>] one siunitx expression per element
      # @param covariance [Array<Array<BigDecimal, Numeric, String>>] n by n,
      #   symmetric and positive semi-definite
      def initialize(values:, units:, covariance:)
        @values = values.map { |v| decimal(v) }.freeze
        @units = units.map { |u| u&.dup&.freeze }.freeze
        @covariance = decimal_rows(covariance).map(&:freeze).freeze
        validate!
      end

      # @return [Array<BigDecimal>] standard uncertainty of each element.
      def uncertainties
        covariance.each_with_index.map { |row, i| row[i].sqrt(SQRT_PRECISION) }
      end

      # @raise [IndexError] when `index` is outside the vector.
      # @return [Real] element `index` as a univariate quantity.
      def [](index)
        ensure_index!(index)
        Real.new(value: values[index], unit: units[index],
                 uncertainty: covariance[index][index].sqrt(SQRT_PRECISION))
      end

      # Assumes independence from `other`.
      # @return [Matrix]
      def +(other)
        ensure_same_units!(other)
        combine(other) { |a, b| a + b }
      end

      # Assumes independence from `other`.
      # @return [Matrix]
      def -(other)
        ensure_same_units!(other)
        combine(other) { |a, b| a - b }
      end

      # Law of propagation of uncertainty: `C_y = J C J^T`.
      #
      # Only the Jacobian's shape is validated. The output values, the
      # Jacobian entries and the output units are the caller's
      # responsibility: this does not derive units from the Jacobian and does
      # not check that `values` is what `jacobian` actually computes.
      #
      # @param values [Array<BigDecimal, Numeric>] output values, length m
      # @param units [Array<String, nil>] output units, length m
      # @param jacobian [Array<Array<BigDecimal, Numeric>>] m by n
      # @return [Matrix]
      def propagate(values:, units:, jacobian:)
        j = decimal_rows(jacobian)
        ensure_jacobian_shape!(j, values.size)
        propagated = QuantityMath.exact_covariance do
          multiply(multiply(j, covariance), j.transpose)
        end
        Matrix.new(values: values, units: units, covariance: propagated)
      end

      def to_s
        values.each_index.map { |i| self[i].to_s }.join(", ")
      end

      private

      # Values combine under the caller's operator. The covariance matrices
      # always add, off-diagonals included, for both `+` and `-`.
      def combine(other, &)
        Matrix.new(
          values: values.zip(other.values).map(&),
          units: units,
          covariance: QuantityMath.exact_covariance do
            add(covariance, other.covariance)
          end,
        )
      end

      # A matching unit vector implies a matching length, so this also guards
      # the element-wise zips.
      def ensure_same_units!(other)
        return if units == other.units

        raise ::ArgumentError,
              "unit mismatch: #{units.inspect} vs #{other.units.inspect}"
      end

      # Negative indices would otherwise wrap silently, and an over-large one
      # would reach `nil[index]` instead of saying what went wrong.
      def ensure_index!(index)
        return if index.between?(0, values.size - 1)

        raise ::IndexError,
              "index #{index} out of range (0...#{values.size})"
      end

      def ensure_jacobian_shape!(jacobian, rows)
        n = values.size
        return if jacobian.size == rows && jacobian.all? { |row| row.size == n }

        raise ::ArgumentError,
              "jacobian shape mismatch: expected #{rows}x#{n}, got " \
              "#{jacobian.size}x#{jacobian.map(&:size).uniq.join(',')}"
      end

      def validate!
        validate_dimensions!
        covariance.each_with_index { |row, i| validate_covariance_row!(row, i) }
        return if semi_definite?

        raise ::ArgumentError, "covariance matrix is not positive semi-definite"
      end

      def validate_dimensions!
        n = values.size
        return if units.size == n && covariance.size == n &&
          covariance.all? { |row| row.size == n }

        raise ::ArgumentError,
              "dimension mismatch: expected #{n} units and a #{n}x#{n} " \
              "covariance matrix"
      end

      def validate_covariance_row!(row, row_index)
        row.each_with_index do |entry, column|
          validate_covariance_entry!(entry, row_index, column)
        end
        return unless row[row_index].negative?

        raise ::ArgumentError,
              "covariance[#{row_index}][#{row_index}] is a negative variance"
      end

      def validate_covariance_entry!(entry, row_index, column)
        unless entry.finite?
          raise ::ArgumentError,
                "covariance[#{row_index}][#{column}] is not finite"
        end
        return if entry == covariance[column][row_index]

        raise ::ArgumentError,
              "covariance is not symmetric at [#{row_index}][#{column}]"
      end

      # LDL^T elimination in exact Rational arithmetic, so there is no
      # tolerance to tune and a legitimately singular matrix is not
      # rejected. Nothing computed here escapes the predicate.
      def semi_definite?
        work = covariance.map { |row| row.map(&:to_r) }
        work.each_index.all? { |index| eliminate_pivot!(work, index) }
      end

      # Eliminates below the pivot at `index`, returning false when that
      # pivot proves the matrix is not positive semi-definite. A zero pivot
      # is only admissible when the rest of its column is zero too.
      def eliminate_pivot!(work, index)
        pivot = work[index][index]
        below = work[(index + 1)..]
        return false if pivot.negative?
        return below.all? { |row| row[index].zero? } if pivot.zero?

        below.each { |row| reduce_row!(row, work[index], index, pivot) }
        true
      end

      def reduce_row!(row, pivot_row, index, pivot)
        factor = row[index] / pivot
        (index...row.size).each do |column|
          row[column] -= factor * pivot_row[column]
        end
      end

      def multiply(left, right)
        columns = right.transpose
        left.map do |row|
          columns.map { |column| row.zip(column).sum { |x, y| x * y } }
        end
      end

      def add(left, right)
        left.zip(right).map { |lr, rr| lr.zip(rr).map { |x, y| x + y } }
      end

      def decimal_rows(rows)
        rows.map { |row| row.map { |x| decimal(x) } }
      end

      # Normalises -0 to 0: it survives the `negative?` variance check but
      # keeps its sign through `sqrt`, which would print an uncertainty of
      # `-0.0`. A non-terminating Rational is rounded to SQRT_PRECISION
      # significant digits.
      def decimal(value)
        decimal = case value
                  when ::BigDecimal then value
                  when ::Rational then BigDecimal(value, SQRT_PRECISION)
                  else BigDecimal(value.to_s)
                  end
        decimal.zero? ? BigDecimal(0) : decimal
      end
    end
  end
end
