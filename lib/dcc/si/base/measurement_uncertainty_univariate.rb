# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:measurementUncertaintyUnivariateType` — choice of standardMU /
      # expandedMU / coverageIntervalMU. Modeled as three optional attributes.
      module MeasurementUncertaintyUnivariate
        def self.included(klass)
          klass.class_eval do
            attribute :standard_mu, :standardMU
            attribute :expanded_mu, :expandedMU
            attribute :coverage_interval_mu, :coverageIntervalMU

            xml do
              namespace ::Dcc::Namespace::Si
              element "measurementUncertaintyUnivariate"
              ordered
              map_element "standardMU", to: :standard_mu
              map_element "expandedMU", to: :expanded_mu
              map_element "coverageIntervalMU", to: :coverage_interval_mu
            end
          end
        end
      end
    end
  end
end