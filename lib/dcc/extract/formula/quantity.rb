# frozen_string_literal: true

module Dcc
  module Extract
    module Formula
      # Value object representing a parsed D-SI quantity for formula
      # evaluation. Carries BigDecimal value, unit string, and optional
      # uncertainty for propagation.
      class Quantity
        attr_reader :value, :unit, :uncertainty

        def initialize(value:, unit: nil, uncertainty: nil)
          @value = value
          @unit = unit
          @uncertainty = uncertainty
        end
      end
    end
  end
end