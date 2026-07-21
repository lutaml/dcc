# frozen_string_literal: true

# XML-list variant of coverageIntervalMU.
module Dcc::Si::V2
  class CoverageIntervalMUXMLList < CommonElements
    attribute :value_standard_mu_xml_list, ::Dcc::Type::DecimalXmlList
    attribute :interval_min_xml_list, ::Dcc::Type::DecimalXmlList
    attribute :interval_max_xml_list, ::Dcc::Type::DecimalXmlList
    attribute :coverage_probability_xml_list, :string
    attribute :distribution_xml_list, :string

    xml do
      namespace ::Dcc::Namespace::Si
      element "coverageIntervalMUXMLList"
      ordered
      map_element "valueStandardMUXMLList", to: :value_standard_mu_xml_list
      map_element "intervalMinXMLList", to: :interval_min_xml_list
      map_element "intervalMaxXMLList", to: :interval_max_xml_list
      map_element "coverageProbabilityXMLList", to: :coverage_probability_xml_list
      map_element "distributionXMLList", to: :distribution_xml_list
    end
  end
  Configuration.register_model(CoverageIntervalMUXMLList, id: :coverageIntervalMUXMLList)
end
