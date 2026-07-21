# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:quantityType` — DCC quantity wrapper around a D-SI quantity element.
    # The XSD allows any of: si:real, si:complex, si:constant, si:hybrid,
    # si:list, si:realListXMLList, si:complexListXMLList, or noQuantity.
    #
    # We use Option B (one attribute per substitution element) — the most
    # reliable pattern in current lutaml-model. Each si:* element resolves
    # via the active type registry to the version-appropriate D-SI class
    # (`Dcc::Si::V2::Real` under `:dcc_v3`, `Dcc::Si::V1::Real` under
    # `:dcc_v2`, etc.).
    module Quantity
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :no_quantity, :string
          # D-SI quantity substitutions (Option B)
          attribute :real, :real, collection: true
          attribute :complex, :complex, collection: true
          attribute :constant, :constant, collection: true
          attribute :hybrid, :hybrid, collection: true
          attribute :real_list_xml_list, :realListXMLList, collection: true
          attribute :complex_list_xml_list, :complexListXMLList, collection: true
          attribute :list, :list, collection: true
          # Ancillary DCC sections
          attribute :used_methods, :usedMethods
          attribute :used_software, :softwareList
          attribute :influence_conditions, :influenceConditions
          attribute :measurement_meta_data, :measurementMetaData

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "quantity"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "noQuantity", to: :no_quantity
            map_element "real", to: :real
            map_element "complex", to: :complex
            map_element "constant", to: :constant
            map_element "hybrid", to: :hybrid
            map_element "realListXMLList", to: :real_list_xml_list
            map_element "complexListXMLList", to: :complex_list_xml_list
            map_element "list", to: :list
            map_element "usedMethods", to: :used_methods
            map_element "usedSoftware", to: :used_software
            map_element "influenceConditions", to: :influence_conditions
            map_element "measurementMetaData", to: :measurement_meta_data
          end
        end
      end
    end
  end
end
