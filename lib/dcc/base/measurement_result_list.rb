# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:measurementResultListType` — collection of `dcc:measurementResult`.
    # Also serves as the root element under `digitalCalibrationCertificate`.
    module MeasurementResultList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :measurement_result, :measurementResult, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "measurementResults"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "measurementResult", to: :measurement_result
          end
        end
      end
    end
  end
end
