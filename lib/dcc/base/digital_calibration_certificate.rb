# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:digitalCalibrationCertificateType` — the root element of every DCC
    # document. Carries `schemaVersion` attribute plus four "rings":
    # administrativeData, measurementResults, optional comment, optional
    # document. From v3.4 also optional `ds:Signature` collection.
    module DigitalCalibrationCertificate
      def self.included(klass)
        klass.class_eval do
          attribute :schema_version, ::Dcc::Type::SchemaVersion
          attribute :administrative_data, :administrativeData
          attribute :measurement_results, :measurementResults
          attribute :comment, :comment
          attribute :document, :byteData

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "digitalCalibrationCertificate"
            ordered
            map_attribute "schemaVersion", to: :schema_version
            map_element "administrativeData", to: :administrative_data
            map_element "measurementResults", to: :measurement_results
            map_element "comment", to: :comment
            map_element "document", to: :document
          end
        end
      end
    end
  end
end
