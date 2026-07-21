# frozen_string_literal: true

# XML-list variant of standard_mu. Stores space-separated decimals.
module Dcc::Si::V2
  class StandardMUXMLList < CommonElements
    attribute :value_standard_mu_xml_list, ::Dcc::Type::DecimalXmlList
    attribute :distribution_xml_list, :string

    xml do
      namespace ::Dcc::Namespace::Si
      element "standardMUXMLList"
      ordered
      map_element "valueStandardMUXMLList", to: :value_standard_mu_xml_list
      map_element "distributionXMLList", to: :distribution_xml_list
    end
  end
  Configuration.register_model(StandardMUXMLList, id: :standardMUXMLList)
end
