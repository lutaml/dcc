# frozen_string_literal: true

module Dcc
  module Si
    module Base
      # `si:listType` — recursive list container for nested quantity lists.
      module SiList
        def self.included(klass)
          klass.class_eval do
            attribute :id, :string
            attribute :ref_type, :string
            attribute :label, :string
            attribute :date_time, :date_time
            attribute :real_list, :real, collection: true
            attribute :real_list_xml_list, :realListXMLList, collection: true
            attribute :complex_list_xml_list, :complexListXMLList, collection: true
            attribute :list, :list, collection: true

            xml do
              namespace ::Dcc::Namespace::Si
              element "list"
              ordered
              map_attribute "id", to: :id
              map_attribute "refType", to: :ref_type
              map_element "label", to: :label
              map_element "dateTime", to: :date_time
              map_element "realList", to: :real_list
              map_element "realListXMLList", to: :real_list_xml_list
              map_element "complexListXMLList", to: :complex_list_xml_list
              map_element "list", to: :list
            end
          end
        end
      end
    end
  end
end