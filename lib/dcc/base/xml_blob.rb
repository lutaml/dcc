# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:xmlType` — opaque wildcard XML payload (`xs:any namespace="##other"`).
    module XmlBlob
      def self.included(klass)
        klass.class_eval do
          attribute :raw, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "xml"
            map_all to: :raw
          end
        end
      end
    end
  end
end
