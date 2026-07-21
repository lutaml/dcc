# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:quantityType` — DCC quantity wrapper around a D-SI quantity element
    # (`si:real`, `si:complex`, `si:constant`, `si:hybrid`, `si:list`, etc.).
    # Also has its own name, usedMethods, usedSoftware, influenceConditions,
    # measurementMetaData.
    #
    # We use Option B (one attribute per substitution element) since this is
    # the most reliable pattern in current lutaml-model. The version wrappers
    # (`Dcc::V2::Quantity`, `Dcc::V3::Quantity`) re-declare these attributes
    # with the version-appropriate D-SI class so the right type resolves at
    # parse time.
    module Quantity
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :no_quantity, :string
          attribute :used_methods, :usedMethods
          attribute :used_software, :softwareList
          attribute :influence_conditions, :influenceConditions
          attribute :measurement_meta_data, :measurementMetaData

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "quantity"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "noQuantity", to: :no_quantity
            map_element "usedMethods", to: :used_methods
            map_element "usedSoftware", to: :used_software
            map_element "influenceConditions", to: :influence_conditions
            map_element "measurementMetaData", to: :measurement_meta_data
          end
        end
      end
    end
  end
end
