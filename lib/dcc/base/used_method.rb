# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:usedMethodType` — calibration method with name/description/norm.
    module UsedMethod
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :description, :text
          attribute :norm, :text, collection: true

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "usedMethod"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "description", to: :description
            map_element "norm", to: :norm
          end
        end
      end
    end
  end
end
