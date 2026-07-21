# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:listType` — recursive list of quantities or sub-lists. Same
    # ancillary sections as Quantity (usedMethods, usedSoftware, etc.).
    module List
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :table_dimension, :integer
          attribute :name, :text
          attribute :date_time, :date_time
          attribute :quantity, :quantity, collection: true
          attribute :list, :list, collection: true
          attribute :used_methods, :usedMethods
          attribute :used_software, :softwareList
          attribute :influence_conditions, :influenceConditions
          attribute :measurement_meta_data, :measurementMetaData

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "list"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_attribute "tableDimension", to: :table_dimension
            map_element "name", to: :name
            map_element "dateTime", to: :date_time
            map_element "quantity", to: :quantity
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
