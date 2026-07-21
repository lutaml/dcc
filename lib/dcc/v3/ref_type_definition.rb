# frozen_string_literal: true

module Dcc::V3
  class RefTypeDefinition < CommonElements
    include ::Dcc::Base::RefTypeDefinition
  end
  Configuration.register_model(RefTypeDefinition, id: :refTypeDefinition)
end
