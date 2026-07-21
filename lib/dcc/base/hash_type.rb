# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:hashType` — reference to a previous report. Used by `previousReport`
    # in `coreData`.
    module HashType
      def self.included(klass)
        klass.class_eval do
          attribute :referral, :string
          attribute :referral_id, :string
          attribute :procedure, :string
          attribute :value, :string
          attribute :description, :text
          attribute :traceable, :boolean
          attribute :in_validity_range, :boolean

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "previousReport"
            ordered
            map_element "referral", to: :referral
            map_element "referralID", to: :referral_id
            map_element "procedure", to: :procedure
            map_element "value", to: :value
            map_element "description", to: :description
            map_element "traceable", to: :traceable
            map_element "inValidityRange", to: :in_validity_range
          end
        end
      end
    end
  end
end
