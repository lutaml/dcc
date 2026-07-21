# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:measurementResultType` — single result block containing name,
    # usedMethods, usedSoftware, measuringEquipments, influenceConditions,
    # results.
    module MeasurementResult
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :description, :text
          attribute :used_methods, :usedMethods
          attribute :used_software, :softwareList
          attribute :measuring_equipments, :measuringEquipments
          attribute :influence_conditions, :influenceConditions
          attribute :results, :results

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "measurementResult"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "description", to: :description
            map_element "usedMethods", to: :used_methods
            map_element "usedSoftware", to: :used_software
            map_element "measuringEquipments", to: :measuring_equipments
            map_element "influenceConditions", to: :influence_conditions
            map_element "results", to: :results
          end
        end
      end
    end
  end
end
