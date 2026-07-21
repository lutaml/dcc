# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:equipmentClassType` — classification reference for measuring
    # equipment. Carries a reference (URI) and a classID.
    module EquipmentClass
      def self.included(klass)
        klass.class_eval do
          attribute :reference, :string
          attribute :class_id, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "equipmentClass"
            ordered
            map_element "reference", to: :reference
            map_element "classID", to: :class_id
          end
        end
      end
    end
  end
end
