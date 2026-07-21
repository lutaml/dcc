# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:textType` — multilingual text container. Holds one or more
    # `dcc:content` elements (each carrying `xml:lang`).
    module Text
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :content, :content, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "text"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "content", to: :content
          end
        end
      end
    end
  end
end
