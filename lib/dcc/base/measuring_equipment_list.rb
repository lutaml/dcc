# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:measuringEquipmentListType` — container of measuring equipment
    # plus shared name/equipmentClass/description/owner/identifications.
    module MeasuringEquipmentList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :equipment_class, :equipmentClass, collection: true
          attribute :description, :richContent
          attribute :owner, :contact
          attribute :identifications, :identifications
          attribute :measuring_equipment, :measuringEquipment, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "measuringEquipments"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "equipmentClass", to: :equipment_class
            map_element "description", to: :description
            map_element "owner", to: :owner
            map_element "identifications", to: :identifications
            map_element "measuringEquipment", to: :measuring_equipment
          end
        end
      end
    end
  end
end
