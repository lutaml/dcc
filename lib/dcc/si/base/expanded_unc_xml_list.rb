# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:expandedUncXMLListType` — compact expanded uncertainty paired
      # with a `realListXMLList`. Used in PTB's valid.xml.
      module ExpandedUncXmlList
        def self.included(klass)
          klass.class_eval do
            attribute :uncertainty_xml_list, ::Dcc::Type::DecimalXmlList
            attribute :coverage_factor_xml_list, :string
            attribute :coverage_probability_xml_list, :string
            attribute :distribution_xml_list, :string

            xml do
              namespace ::Dcc::Namespace::Si
              element "expandedUncXMLList"
              ordered
              map_element "uncertaintyXMLList", to: :uncertainty_xml_list
              map_element "coverageFactorXMLList", to: :coverage_factor_xml_list
              map_element "coverageProbabilityXMLList", to: :coverage_probability_xml_list
              map_element "distributionXMLList", to: :distribution_xml_list
            end
          end
        end
      end
    end
  end
end