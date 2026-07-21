# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:respPersonType` — responsible person with role flags for digital
    # sealing and signing.
    module RespPerson
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :person, :contact
          attribute :description, :text
          attribute :main_signer, :boolean
          attribute :crypt_electronic_seal, :string
          attribute :crypt_electronic_signature, :string
          attribute :crypt_electronic_time_stamp, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "respPerson"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "person", to: :person
            map_element "description", to: :description
            map_element "mainSigner", to: :main_signer
            map_element "cryptElectronicSeal", to: :crypt_electronic_seal
            map_element "cryptElectronicSignature", to: :crypt_electronic_signature
            map_element "cryptElectronicTimeStamp", to: :crypt_electronic_time_stamp
          end
        end
      end
    end
  end
end
