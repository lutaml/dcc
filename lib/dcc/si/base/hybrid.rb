# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:hybridType` — multi-unit adapter. Wraps one or more quantity
      # representations (real, realListXMLList, complex, etc.) that express
      # the same measurand in different units. At least one SI unit is
      # required per the XSD.
      module Hybrid
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label, :string
            attribute :quantity_type, :string
            attribute :real, :real, collection: true
            attribute :complex, :complex, collection: true
            attribute :constant, :constant, collection: true
            attribute :real_list_xml_list, :realListXMLList, collection: true
            attribute :complex_list_xml_list, :complexListXMLList, collection: true

            xml do
              namespace ::Dcc::Namespace::Si
              element "hybrid"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "label", to: :label
              map_element "quantityType", to: :quantity_type
              map_element "real", to: :real
              map_element "complex", to: :complex
              map_element "constant", to: :constant
              map_element "realListXMLList", to: :real_list_xml_list
              map_element "complexListXMLList", to: :complex_list_xml_list
            end
          end
        end
      end
    end
  end
end