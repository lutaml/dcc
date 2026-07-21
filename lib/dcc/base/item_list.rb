# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:itemListType` — container of `dcc:item`. Also has its own name,
    # equipmentClass, description, owner, identifications.
    module ItemList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :equipment_class, :equipmentClass, collection: true
          attribute :description, :richContent
          attribute :owner, :contact
          attribute :identifications, :identifications
          attribute :item, :item, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "items"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "equipmentClass", to: :equipment_class
            map_element "description", to: :description
            map_element "owner", to: :owner
            map_element "identifications", to: :identifications
            map_element "item", to: :item
          end
        end
      end
    end
  end
end
