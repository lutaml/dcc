# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:coverageIntervalMUType` — coverage interval uncertainty.
      module CoverageIntervalMU
        def self.included(klass)
          klass.class_eval do
            attribute :value_standard_mu, :string
            attribute :interval_min, :string
            attribute :interval_max, :string
            attribute :coverage_probability, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "coverageIntervalMU"
              ordered
              map_element "valueStandardMU", to: :value_standard_mu
              map_element "intervalMin", to: :interval_min
              map_element "intervalMax", to: :interval_max
              map_element "coverageProbability", to: :coverage_probability
              map_element "distribution", to: :distribution
            end
          end
        end
      end
    end
  end
end