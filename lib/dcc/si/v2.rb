# frozen_string_literal: true

# `Dcc::Si::V2` hosts D-SI v2.x element wrappers registered in the `:dsi_v2`
# context. They share the same `lib/dcc/si/base/*.rb` mapping modules as V1
# but live in their own class hierarchy so the two versions can coexist.
module Dcc
  module Si
    module V2
      autoload :Configuration, "dcc/si/v2/configuration"
      autoload :CommonElements, "dcc/si/v2/common_elements"
      autoload :Namespace, "dcc/si/v2/namespace"

      autoload :Real, "dcc/si/v2/real"
      autoload :Complex, "dcc/si/v2/complex"
      autoload :Constant, "dcc/si/v2/constant"
      autoload :RealListXmlList, "dcc/si/v2/real_list_xml_list"
      autoload :ComplexListXmlList, "dcc/si/v2/complex_list_xml_list"
      autoload :Hybrid, "dcc/si/v2/hybrid"
      autoload :SiList, "dcc/si/v2/si_list"
      autoload :StandardMU, "dcc/si/v2/standard_mu"
      autoload :StandardMUXMLList, "dcc/si/v2/standard_mu_xml_list"
      autoload :ExpandedMU, "dcc/si/v2/expanded_mu"
      autoload :ExpandedMUXMLList, "dcc/si/v2/expanded_mu_xml_list"
      autoload :CoverageIntervalMU, "dcc/si/v2/coverage_interval_mu"
      autoload :CoverageIntervalMUXMLList, "dcc/si/v2/coverage_interval_mu_xml_list"
      autoload :ExpandedUncXmlList, "dcc/si/v2/expanded_unc_xml_list"
      autoload :MeasurementUncertaintyUnivariate, "dcc/si/v2/measurement_uncertainty_univariate"

      ROOT_ELEMENT_TAG = "real"

      extend ::Dcc::VersionedParser

      ELEMENT_CLASSES = %i[
        Real Complex Constant
        RealListXmlList ComplexListXmlList Hybrid SiList
        StandardMU StandardMUXMLList
        ExpandedMU ExpandedMUXMLList
        CoverageIntervalMU CoverageIntervalMUXMLList
        ExpandedUncXmlList MeasurementUncertaintyUnivariate
      ].freeze

      def self.load_all!
        ELEMENT_CLASSES.each { |name| const_get(name) }
        Configuration.populate_context!
        true
      end
    end
  end
end