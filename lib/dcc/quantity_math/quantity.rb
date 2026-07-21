# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module QuantityMath
    # A simple `(value, unit, uncertainty)` value object used by
    # `Dcc::QuantityMath::Real` for arithmetic. Immutable.
    class Quantity
      attr_reader :value, :unit, :uncertainty

      # @param value [BigDecimal, Numeric]
      # @param unit [String, nil] siunitx expression
      # @param uncertainty [BigDecimal, Numeric, nil] 1σ absolute uncertainty
      def initialize(value:, unit: nil, uncertainty: nil)
        @value = cast_decimal(value)
        @unit = unit
        @uncertainty = uncertainty.nil? ? nil : cast_decimal(uncertainty)
      end

      # @return [Boolean] whether the quantity carries uncertainty info.
      def uncertain?
        !uncertainty.nil?
      end

      # @return [Boolean] whether units match (or both are nil).
      def same_unit?(other)
        unit == other.unit
      end

      def to_s
        u = uncertain? ? " ± #{uncertainty}" : ""
        n = unit ? " #{unit}" : ""
        "#{value}#{u}#{n}"
      end

      private

      def cast_decimal(value)
        return value if value.is_a?(::BigDecimal)

        BigDecimal(value.to_s)
      end
    end
  end
end