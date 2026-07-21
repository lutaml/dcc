# frozen_string_literal: true

# DCC v2.x has no `dcc:refTypeDefinitionType`; this is a v3.x addition. We
# register an empty V2 placeholder so documents that happen to include the
# element (mixed-version transitional documents) parse without error.
module Dcc::V2
  class RefTypeDefinition < CommonElements
    # Deliberately empty; v2 has no refTypeDefinition structure.
  end
  Configuration.register_model(RefTypeDefinition, id: :refTypeDefinition)
end
