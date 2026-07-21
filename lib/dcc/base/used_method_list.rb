# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:usedMethodListType` — collection of `dcc:usedMethod`.
    module UsedMethodList
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :used_method, :usedMethod, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "usedMethods"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "usedMethod", to: :used_method
          end
        end
      end
    end
  end
end
