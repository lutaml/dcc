# frozen_string_literal: true

module Dcc::V2
  # v2 calls the influence condition's state element `state`; v3 renamed it to
  # `status`, which the shared base module carries.
  class Condition < CommonElements
    attribute :id, :string
    attribute :ref_id, :string
    attribute :ref_type, :string
    attribute :name, :text
    attribute :description, :text
    attribute :status, :string
    attribute :data, :data, collection: true

    xml do
      namespace ::Dcc::Namespace::Dcc
      element "influenceCondition"
      ordered
      map_attribute "id", to: :id
      map_attribute "refId", to: :ref_id
      map_attribute "refType", to: :ref_type
      map_element "name", to: :name
      map_element "description", to: :description
      map_element "state", to: :status
      map_element "data", to: :data
    end
  end
  Configuration.register_model(Condition, id: :influenceCondition)
end
