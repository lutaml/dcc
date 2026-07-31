# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:expandedUncType` — expanded uncertainty stated directly on a real
      # quantity. The v1 form; v2 keeps it as a deprecated alternative to
      # `measurementUncertaintyUnivariate`.
      module ExpandedUnc
        # rubocop:disable Metrics/MethodLength -- one lutaml mapping
        # block, written the same way as every sibling D-SI module.
        def self.included(klass)
          klass.class_eval do
            attribute :uncertainty, :string
            attribute :coverage_factor, :string
            attribute :coverage_probability, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "expandedUnc"
              ordered
              map_element "uncertainty", to: :uncertainty
              map_element "coverageFactor", to: :coverage_factor
              map_element "coverageProbability", to: :coverage_probability
              map_element "distribution", to: :distribution
            end
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
