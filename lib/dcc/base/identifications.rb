# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:identificationListType` — collection of identifications.
    module Identifications
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :identification, :identification, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "identifications"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "identification", to: :identification
          end
        end
      end
    end
  end
end
