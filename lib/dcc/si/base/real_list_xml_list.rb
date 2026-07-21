# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:realListXMLListType` — compact space-separated list of real
      # measurement quantities. Each component (values, units, uncertainty)
      # is itself a space-separated XML list.
      module RealListXmlList
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label_xml_list, :string
            attribute :quantity_type_xml_list, :string
            attribute :value_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :unit_xml_list, :string
            attribute :significant_digit_xml_list, :string
            attribute :date_time_xml_list, :string
            attribute :expanded_unc_xml_list, :expandedUncXMLList
            attribute :standard_mu_xml_list, :standardMUXMLList
            attribute :coverage_interval_mu_xml_list, :coverageIntervalMUXMLList

            xml do
              namespace ::Dcc::Namespace::Si
              element "realListXMLList"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "labelXMLList", to: :label_xml_list
              map_element "quantityTypeXMLList", to: :quantity_type_xml_list
              map_element "valueXMLList", to: :value_xml_list
              map_element "unitXMLList", to: :unit_xml_list
              map_element "significantDigitXMLList", to: :significant_digit_xml_list
              map_element "dateTimeXMLList", to: :date_time_xml_list
              map_element "expandedUncXMLList", to: :expanded_unc_xml_list
              map_element "standardMUXMLList", to: :standard_mu_xml_list
              map_element "coverageIntervalMUXMLList", to: :coverage_interval_mu_xml_list
            end
          end
        end
      end
    end
  end
end