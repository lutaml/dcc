# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:expandedMUType` — expanded measurement uncertainty (k × σ).
      module ExpandedMU
        def self.included(klass)
          klass.class_eval do
            attribute :value_expanded_mu, :string
            attribute :coverage_factor, :string
            attribute :coverage_probability, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "expandedMU"
              ordered
              map_element "valueExpandedMU", to: :value_expanded_mu
              map_element "coverageFactor", to: :coverage_factor
              map_element "coverageProbability", to: :coverage_probability
              map_element "distribution", to: :distribution
            end
          end
        end
      end
    end
  end
end