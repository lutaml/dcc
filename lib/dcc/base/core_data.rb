# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:coreDataType` — core administrative metadata: country, languages,
    # unique identifier, dates, previous report, identifications.
    module CoreData
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :country_code_iso_3166_1, ::Dcc::Type::IsoCountryCode
          attribute :used_lang_code_iso_639_1, ::Dcc::Type::IsoLanguageCode, collection: true
          attribute :mandatory_lang_code_iso_639_1, ::Dcc::Type::IsoLanguageCode, collection: true
          attribute :unique_identifier, :string
          attribute :identifications, :identifications
          attribute :receipt_date, :date
          attribute :begin_performance_date, :date
          attribute :end_performance_date, :date
          attribute :previous_report, :previousReport

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "coreData"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "countryCodeISO3166_1", to: :country_code_iso_3166_1
            map_element "usedLangCodeISO639_1", to: :used_lang_code_iso_639_1
            map_element "mandatoryLangCodeISO639_1", to: :mandatory_lang_code_iso_639_1
            map_element "uniqueIdentifier", to: :unique_identifier
            map_element "identifications", to: :identifications
            map_element "receiptDate", to: :receipt_date
            map_element "beginPerformanceDate", to: :begin_performance_date
            map_element "endPerformanceDate", to: :end_performance_date
            map_element "previousReport", to: :previous_report
          end
        end
      end
    end
  end
end
