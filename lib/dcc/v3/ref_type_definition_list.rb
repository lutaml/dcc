# frozen_string_literal: true

module Dcc::V3
  class RefTypeDefinitionList < CommonElements
    include ::Dcc::Base::RefTypeDefinitionList
  end
  Configuration.register_model(RefTypeDefinitionList, id: :refTypeDefinitions)
end
