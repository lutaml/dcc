# frozen_string_literal: true

# XML-list variant of expandedMU. Stores space-separated decimals.
module Dcc::Si::V2
  class ExpandedMUXMLList < CommonElements
    attribute :value_expanded_mu_xml_list, ::Dcc::Type::DecimalXmlList
    attribute :coverage_factor_xml_list, :string
    attribute :coverage_probability_xml_list, :string
    attribute :distribution_xml_list, :string

    xml do
      namespace ::Dcc::Namespace::Si
      element "expandedMUXMLList"
      ordered
      map_element "valueExpandedMUXMLList", to: :value_expanded_mu_xml_list
      map_element "coverageFactorXMLList", to: :coverage_factor_xml_list
      map_element "coverageProbabilityXMLList", to: :coverage_probability_xml_list
      map_element "distributionXMLList", to: :distribution_xml_list
    end
  end
  Configuration.register_model(ExpandedMUXMLList, id: :expandedMUXMLList)
end
