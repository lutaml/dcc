# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:textType` — multilingual text container. Holds interleaved
    # `dcc:content` (localized text), `dcc:file` (byteData), and
    # `dcc:formula` elements per the v3.3.0 XSD content model.
    module Text
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :content, :content, collection: true
          attribute :file, :byteData, collection: true
          attribute :formula, :formula, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "text"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "content", to: :content
            map_element "file", to: :file
            map_element "formula", to: :formula
          end
        end
      end
    end
  end
end