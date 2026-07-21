# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:calibrationLaboratoryType` — lab code plus contact info.
    module CalibrationLaboratory
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :calibration_laboratory_code, :string
          attribute :contact, :contact, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "calibrationLaboratory"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "calibrationLaboratoryCode", to: :calibration_laboratory_code
            map_element "contact", to: :contact
          end
        end
      end
    end
  end
end
