# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:richContentType` (v3.4+) — combines text, files, and formulae into
    # one content block. We model it as an ordered collection of variants.
    module RichContent
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :text, :text, collection: true
          attribute :formula, :formula, collection: true
          attribute :byte_data, :byteData, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "richContent"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "text", to: :text
            map_element "formula", to: :formula
            map_element "byteData", to: :byte_data
          end
        end
      end
    end
  end
end
