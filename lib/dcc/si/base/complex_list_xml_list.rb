# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:complexListXMLListType` — compact list of complex quantities.
      module ComplexListXmlList
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label_xml_list, :string
            attribute :value_real_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :value_imag_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :value_magnitude_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :value_phase_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :unit_xml_list, :string
            attribute :unit_phase_xml_list, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "complexListXMLList"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "labelXMLList", to: :label_xml_list
              map_element "valueRealXMLList", to: :value_real_xml_list
              map_element "valueImagXMLList", to: :value_imag_xml_list
              map_element "valueMagnitudeXMLList", to: :value_magnitude_xml_list
              map_element "valuePhaseXMLList", to: :value_phase_xml_list
              map_element "unitXMLList", to: :unit_xml_list
              map_element "unitPhaseXMLList", to: :unit_phase_xml_list
            end
          end
        end
      end
    end
  end
end