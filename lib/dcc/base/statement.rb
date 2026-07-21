# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:statementMetaDataType` — generic statement block used for conformity,
    # traceability, validity range, etc. Carries a refType classifier.
    module Statement
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :country_code_iso_3166_1, ::Dcc::Type::IsoCountryCode
          attribute :convention, :string
          attribute :traceable, :boolean
          attribute :norm, :text
          attribute :reference, :text
          attribute :declaration, :text
          attribute :valid, :boolean
          attribute :ref_id_statement, :string
          attribute :date, :date
          attribute :period, :string
          attribute :non_si_unit, :string
          attribute :non_si_definition, :text

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "statement"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "countryCodeISO3166_1", to: :country_code_iso_3166_1
            map_element "convention", to: :convention
            map_element "traceable", to: :traceable
            map_element "norm", to: :norm
            map_element "reference", to: :reference
            map_element "declaration", to: :declaration
            map_element "valid", to: :valid
            map_element "refId", to: :ref_id_statement
            map_element "date", to: :date
            map_element "period", to: :period
            map_element "nonSIUnit", to: :non_si_unit
            map_element "nonSIDefinition", to: :non_si_definition
          end
        end
      end
    end
  end
end
