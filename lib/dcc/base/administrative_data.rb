# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:administrativeDataType` — top-level admin section. Uses `xs:all`
    # ordering (children may appear in any order) so we keep the explicit
    # `ordered` for serialization determinism.
    module AdministrativeData
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :dcc_software, :softwareList
          attribute :ref_type_definitions, :refTypeDefinitions
          attribute :core_data, :coreData
          attribute :items, :items
          attribute :calibration_laboratory, :calibrationLaboratory
          attribute :resp_persons, :respPersons
          attribute :customer, :contact
          attribute :statements, :statements

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "administrativeData"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "dccSoftware", to: :dcc_software
            map_element "refTypeDefinitions", to: :ref_type_definitions
            map_element "coreData", to: :core_data
            map_element "items", to: :items
            map_element "calibrationLaboratory", to: :calibration_laboratory
            map_element "respPersons", to: :resp_persons
            map_element "customer", to: :customer
            map_element "statements", to: :statements
          end
        end
      end
    end
  end
end
