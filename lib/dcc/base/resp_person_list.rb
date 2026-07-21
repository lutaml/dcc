# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:respPersonListType` — collection of `dcc:respPerson`.
    module RespPersonList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :resp_person, :respPerson, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "respPersons"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "respPerson", to: :resp_person
          end
        end
      end
    end
  end
end
