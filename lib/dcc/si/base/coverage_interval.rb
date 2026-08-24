# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:coverageIntervalType` — coverage interval stated directly on a real
      # quantity, the sibling of `expandedUnc` in the same xs:choice. The v1
      # form; v2 keeps it as a deprecated alternative.
      module CoverageInterval
        # rubocop:disable Metrics/MethodLength -- one lutaml mapping
        # block, written the same way as every sibling D-SI module.
        def self.included(klass)
          klass.class_eval do
            attribute :standard_unc, :string
            attribute :interval_min, :string
            attribute :interval_max, :string
            attribute :coverage_probability, :string
            attribute :distribution, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "coverageInterval"
              ordered
              map_element "standardUnc", to: :standard_unc
              map_element "intervalMin", to: :interval_min
              map_element "intervalMax", to: :interval_max
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
