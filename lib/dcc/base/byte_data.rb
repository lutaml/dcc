# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:byteDataType` — embedded binary file with name/description/filename/
    # mime-type/base64 data.
    module ByteData
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :description, :text
          attribute :file_name, :string
          attribute :mime_type, :string
          attribute :data_base64, ::Dcc::Type::Base64Binary

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "byteData"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "description", to: :description
            map_element "fileName", to: :file_name
            map_element "mimeType", to: :mime_type
            map_element "dataBase64", to: :data_base64
          end
        end
      end
    end
  end
end
