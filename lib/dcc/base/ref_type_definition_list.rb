# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:refTypeDefinitionListType` — collection of `dcc:refTypeDefinition`.
    module RefTypeDefinitionList
      def self.included(klass)
        klass.class_eval do
          attribute :ref_type_definition, :refTypeDefinition, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "refTypeDefinitions"
            ordered
            map_element "refTypeDefinition", to: :ref_type_definition
          end
        end
      end
    end
  end
end
