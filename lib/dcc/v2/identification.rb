# frozen_string_literal: true

module Dcc::V2
  # v2 calls the identification's third child `description`; v3 renamed it to
  # `name`, which the shared base module carries.
  class Identification < CommonElements
    attribute :issuer, :string
    attribute :value, :string
    attribute :description, :text

    xml do
      namespace ::Dcc::Namespace::Dcc
      element "identification"
      ordered
      map_element "issuer", to: :issuer
      map_element "value", to: :value
      map_element "description", to: :description
    end
  end
  Configuration.register_model(Identification, id: :identification)
end
