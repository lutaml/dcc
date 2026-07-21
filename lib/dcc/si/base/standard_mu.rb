# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:standardMUType` — standard measurement uncertainty (1σ).
      module StandardMU
        def self.included(klass)
          klass.class_eval do
            attribute :value_standard_mu, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "standardMU"
              ordered
              map_element "valueStandardMU", to: :value_standard_mu
              map_element "distribution", to: :distribution
            end
          end
        end
      end
    end
  end
end