# frozen_string_literal: true

module Dcc::V2
  class RefTypeDefinitionList < CommonElements
    attribute :ref_type_definition, :refTypeDefinition, collection: true

    xml do
      namespace ::Dcc::Namespace::Dcc
      element "refTypeDefinitions"
      ordered
      map_element "refTypeDefinition", to: :ref_type_definition
    end
  end
  Configuration.register_model(RefTypeDefinitionList, id: :refTypeDefinitions)
end
