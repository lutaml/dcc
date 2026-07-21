# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:refTypeDefinitionType` (v3.4+) — declares a refType namespace and
    # source link. Used in `administrativeData/refTypeDefinitions`.
    module RefTypeDefinition
      def self.included(klass)
        klass.class_eval do
          attribute :ref_type, :string
          attribute :name, :text
          attribute :description, :richContent
          attribute :namespace, :string
          attribute :link, :string
          attribute :release, :string
          attribute :value, :string
          attribute :procedure, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "refTypeDefinition"
            ordered
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "description", to: :description
            map_element "namespace", to: :namespace
            map_element "link", to: :link
            map_element "release", to: :release
            map_element "value", to: :value
            map_element "procedure", to: :procedure
          end
        end
      end
    end
  end
end
