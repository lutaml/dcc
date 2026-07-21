# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:realQuantityType` — single real measurement quantity with
      # optional univariate uncertainty.
      #
      # Wire format:
      #   <si:real>
      #     <si:label>...</si:label>
      #     <si:value>42.0</si:value>
      #     <si:unit>\kelvin</si:unit>
      #     <si:measurementUncertaintyUnivariate>
      #       <si:expandedMU>...</si:expandedMU>
      #     </si:measurementUncertaintyUnivariate>
      #   </si:real>
      module Real
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label, :string
            attribute :value, :string
            attribute :unit, ::Dcc::Type::SiUnit
            attribute :significant_digit, :integer
            attribute :date_time, :date_time
            attribute :measurement_uncertainty_univariate, :measurementUncertaintyUnivariate

            xml do
              namespace ::Dcc::Namespace::Si
              element "real"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "label", to: :label
              map_element "value", to: :value
              map_element "unit", to: :unit
              map_element "significantDigit", to: :significant_digit
              map_element "dateTime", to: :date_time
              map_element "measurementUncertaintyUnivariate", to: :measurement_uncertainty_univariate
            end
          end
        end
      end
    end
  end
end