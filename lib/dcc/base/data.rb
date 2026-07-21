# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:dataType` — the central xs:choice container. May hold any of:
    # `text`, `formula`, `byteData`, `xml`, `quantity`, `list`. The XSD allows
    # `maxOccurs="unbounded"` so any of the alternatives may repeat.
    #
    # We model each branch as a collection attribute; the version wrapper
    # resolves `quantity` to the version-appropriate D-SI-aware type.
    module Data
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :text, :text, collection: true
          attribute :formula, :formula, collection: true
          attribute :byte_data, :byteData, collection: true
          attribute :xml, :xml, collection: true
          attribute :quantity, :quantity, collection: true
          attribute :list, :list, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "data"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "text", to: :text
            map_element "formula", to: :formula
            map_element "byteData", to: :byte_data
            map_element "xml", to: :xml
            map_element "quantity", to: :quantity
            map_element "list", to: :list
          end
        end
      end
    end
  end
end
