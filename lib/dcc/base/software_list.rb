# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:softwareListType` — collection of `dcc:software`.
    module SoftwareList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :software, :software, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "softwareList"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "software", to: :software
          end
        end
      end
    end
  end
end
