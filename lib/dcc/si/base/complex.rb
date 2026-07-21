# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:complexQuantityType` — complex number in Cartesian or polar form.
      module Complex
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label, :string
            attribute :value_real, :string
            attribute :value_imag, :string
            attribute :value_magnitude, :string
            attribute :value_phase, :string
            attribute :unit, ::Dcc::Type::SiUnit
            attribute :unit_phase, :string
            attribute :significant_digit, :integer
            attribute :date_time, :date_time

            xml do
              namespace ::Dcc::Namespace::Si
              element "complex"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "label", to: :label
              map_element "valueReal", to: :value_real
              map_element "valueImag", to: :value_imag
              map_element "valueMagnitude", to: :value_magnitude
              map_element "valuePhase", to: :value_phase
              map_element "unit", to: :unit
              map_element "unitPhase", to: :unit_phase
              map_element "significantDigit", to: :significant_digit
              map_element "dateTime", to: :date_time
            end
          end
        end
      end
    end
  end
end