# frozen_string_literal: true

module Dcc::V2
  # V2 Quantity: declares DCC admin attributes + D-SI v1.x quantity
  # element references in a single `xml do` block. Follows the same
  # pattern as V3::Quantity but wires D-SI v1 classes.
  class Quantity < CommonElements
    attribute :id, :string
    attribute :ref_id, :string
    attribute :ref_type, :string
    attribute :name, :text
    attribute :no_quantity, :string
    attribute :used_methods, :usedMethods
    attribute :used_software, :softwareList
    attribute :influence_conditions, :influenceConditions
    attribute :measurement_meta_data, :measurementMetaData
    # D-SI v1 quantity substitutions (Option B)
    attribute :real, ::Dcc::Si::V1::Real, collection: true
    attribute :complex, ::Dcc::Si::V1::Complex, collection: true
    attribute :constant, ::Dcc::Si::V1::Constant, collection: true
    attribute :hybrid, ::Dcc::Si::V1::Hybrid, collection: true
    attribute :real_list_xml_list, ::Dcc::Si::V1::RealListXmlList, collection: true
    attribute :complex_list_xml_list, ::Dcc::Si::V1::ComplexListXmlList, collection: true
    attribute :list, ::Dcc::Si::V1::SiList, collection: true

    xml do
      namespace ::Dcc::Namespace::Dcc
      element "quantity"
      ordered
      map_attribute "id", to: :id
      map_attribute "refId", to: :ref_id
      map_attribute "refType", to: :ref_type
      map_element "name", to: :name
      map_element "noQuantity", to: :no_quantity
      map_element "usedMethods", to: :used_methods
      map_element "usedSoftware", to: :used_software
      map_element "influenceConditions", to: :influence_conditions
      map_element "measurementMetaData", to: :measurement_meta_data
      map_element "real", to: :real
      map_element "complex", to: :complex
      map_element "constant", to: :constant
      map_element "hybrid", to: :hybrid
      map_element "realListXMLList", to: :real_list_xml_list
      map_element "complexListXMLList", to: :complex_list_xml_list
      map_element "list", to: :list
    end
  end
  Configuration.register_model(Quantity, id: :quantity)
end
