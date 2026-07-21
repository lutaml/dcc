# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:constantQuantityType` — physical or mathematical constant.
      module Constant
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label, :string
            attribute :value, :string
            attribute :unit, ::Dcc::Type::SiUnit
            attribute :significant_digit, :integer
            attribute :date_time, :date_time
            attribute :value_standard_mu, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "constant"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "label", to: :label
              map_element "value", to: :value
              map_element "unit", to: :unit
              map_element "significantDigit", to: :significant_digit
              map_element "dateTime", to: :date_time
              map_element "valueStandardMU", to: :value_standard_mu
              map_element "distribution", to: :distribution
            end
          end
        end
      end
    end
  end
end