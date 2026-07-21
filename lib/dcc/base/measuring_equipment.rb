# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:measuringEquipmentType` — single instrument used during calibration.
    module MeasuringEquipment
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :equipment_class, :equipmentClass, collection: true
          attribute :description, :richContent
          attribute :certificate, :previousReport
          attribute :manufacturer, :contactNotStrict
          attribute :model, :string
          attribute :identifications, :identifications
          attribute :installed_software, :softwareList

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "measuringEquipment"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "equipmentClass", to: :equipment_class
            map_element "description", to: :description
            map_element "certificate", to: :certificate
            map_element "manufacturer", to: :manufacturer
            map_element "model", to: :model
            map_element "identifications", to: :identifications
            map_element "installedSoftware", to: :installed_software
          end
        end
      end
    end
  end
end
