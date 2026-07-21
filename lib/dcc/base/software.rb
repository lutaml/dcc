# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:softwareType` — name + release + optional type enum + description.
    # v3.4 adds the `type` enum (application/bios/driver/editor/firmware/
    # library/os/other).
    module Software
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :release, :string
          attribute :type, :string
          attribute :description, :richContent

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "software"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "release", to: :release
            map_element "type", to: :type
            map_element "description", to: :description
          end
        end
      end
    end
  end
end
