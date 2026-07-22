# frozen_string_literal: true

# `Dcc::Si::V1` hosts D-SI v1.x element wrappers registered in the
# `:dsi_v1` context. Mirrors the V2 structure but additionally supports
# the deprecated `expandedUnc` type that v2 replaced with `expandedMU`.
module Dcc
  module Si
    module V1
      autoload :Configuration, "dcc/si/v1/configuration"
      autoload :CommonElements, "dcc/si/v1/common_elements"
      autoload :Namespace, "dcc/si/v1/namespace"

      autoload :Real, "dcc/si/v1/real"
      autoload :Complex, "dcc/si/v1/complex"
      autoload :Constant, "dcc/si/v1/constant"
      autoload :RealListXmlList, "dcc/si/v1/real_list_xml_list"
      autoload :ComplexListXmlList, "dcc/si/v1/complex_list_xml_list"
      autoload :Hybrid, "dcc/si/v1/hybrid"
      autoload :SiList, "dcc/si/v1/si_list"
      autoload :List, "dcc/si/v1/si_list"
      autoload :StandardMU, "dcc/si/v1/standard_mu"
      autoload :ExpandedMU, "dcc/si/v1/expanded_mu"
      autoload :CoverageIntervalMU, "dcc/si/v1/coverage_interval_mu"
      autoload :ExpandedUnc, "dcc/si/v1/expanded_unc"
      autoload :ExpandedUncXmlList, "dcc/si/v1/expanded_unc_xml_list"
      autoload :MeasurementUncertaintyUnivariate, "dcc/si/v1/measurement_uncertainty_univariate"

      ROOT_ELEMENT_TAG = "real"

      extend ::Dcc::VersionedParser

      ELEMENT_CLASSES = %i[
        Real Complex Constant
        RealListXmlList ComplexListXmlList Hybrid SiList
        StandardMU ExpandedMU CoverageIntervalMU
        ExpandedUnc ExpandedUncXmlList MeasurementUncertaintyUnivariate
      ].freeze

      def self.load_all!
        ELEMENT_CLASSES.each { |name| const_get(name) }
        Configuration.populate_context!
        true
      end
    end
  end
end
