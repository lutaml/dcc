# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module QuantityMath
    # BigDecimal arithmetic on real-valued quantities with RSS uncertainty
    # propagation for add/sub and fractional propagation for mul/div.
    class Real < Quantity
      # @return [Real]
      def +(other)
        ensure_same_unit!(other)
        Real.new(
          value: value + other.value,
          unit: unit,
          uncertainty: rss_uncertainty(other),
        )
      end

      # @return [Real]
      def -(other)
        ensure_same_unit!(other)
        Real.new(
          value: value - other.value,
          unit: unit,
          uncertainty: rss_uncertainty(other),
        )
      end

      # @return [Real]
      def *(other)
        new_value = value * other.value
        new_unit = compose_unit(unit, other.unit)
        Real.new(
          value: new_value,
          unit: new_unit,
          uncertainty: fractional_uncertainty_mul_div(other, new_value),
        )
      end

      # @return [Real]
      def /(other)
        new_value = value / other.value
        new_unit = compose_unit(unit, inverse_unit(other.unit))
        Real.new(
          value: new_value,
          unit: new_unit,
          uncertainty: fractional_uncertainty_mul_div(other, new_value),
        )
      end

      # @param exponent [Integer]
      # @return [Real]
      def **(exponent)
        new_value = value ** exponent
        Real.new(
          value: new_value,
          unit: unit && "^#{exponent}",
          uncertainty: power_uncertainty(exponent, new_value),
        )
      end

      private

      def ensure_same_unit!(other)
        return if same_unit?(other)

        raise ::ArgumentError,
              "unit mismatch: #{unit.inspect} vs #{other.unit.inspect}"
      end

      # Root-sum-square for add/sub: σ_result = sqrt(σ1² + σ2²)
      def rss_uncertainty(other)
        return nil unless uncertain? && other.uncertain?
        return other.uncertainty if uncertainty.nil?
        return uncertainty if other.uncertainty.nil?

        sum_of_squares = (uncertainty ** 2) + (other.uncertainty ** 2)
        BigDecimal(Math.sqrt(sum_of_squares.to_f).to_s)
      end

      # Fractional for mul/div: σ_y / y = sqrt((σ_a/a)² + (σ_b/b)²)
      def fractional_uncertainty_mul_div(other, new_value)
        return nil unless uncertain? && other.uncertain?
        return nil if value.zero? || other.value.zero?

        a_rel = uncertainty / value
        b_rel = other.uncertainty / other.value
        sum_of_squares = (a_rel ** 2) + (b_rel ** 2)
        BigDecimal(Math.sqrt(sum_of_squares.to_f).to_s) * new_value.abs
      end

      # Power rule: σ_y = |n * x^(n-1)| * σ_x
      def power_uncertainty(exponent, new_value)
        return nil unless uncertain?

        derivative = exponent * (value ** (exponent - 1))
        (derivative.abs * uncertainty)
      end

      def compose_unit(u1, u2)
        return nil if u1.nil? && u2.nil?
        return u1 if u2.nil?
        return u2 if u1.nil?

        "#{u1}\\cdot#{u2}"
      end

      def inverse_unit(u)
        return nil if u.nil?

        "#{u}^-1"
      end
    end
  end
end