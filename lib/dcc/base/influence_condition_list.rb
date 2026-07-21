# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:influenceConditionListType` — collection of `dcc:influenceCondition`
    # plus shared name/description/methods/software/equipment.
    module InfluenceConditionList
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
          attribute :influence_condition, :influenceCondition, collection: true
          attribute :data, :data, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "influenceConditions"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "description", to: :description
            map_element "usedMethods", to: :used_methods
            map_element "usedSoftware", to: :used_software
            map_element "measuringEquipments", to: :measuring_equipments
            map_element "influenceCondition", to: :influence_condition
            map_element "data", to: :data
          end
        end
      end
    end
  end
end
