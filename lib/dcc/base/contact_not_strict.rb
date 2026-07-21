# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:contactNotStrictType` — loose contact (location optional). Used for
    # manufacturers and owners.
    module ContactNotStrict
      def self.included(klass)
        klass.class_eval do
          attribute :id, :string
          attribute :ref_id, :string
          attribute :ref_type, :string
          attribute :name, :text
          attribute :e_mail, :string
          attribute :phone, :string
          attribute :fax, :string
          attribute :location, :location
          attribute :description_data, :text

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "contactNotStrict"
            ordered
            map_attribute "id", to: :id
            map_attribute "refId", to: :ref_id
            map_attribute "refType", to: :ref_type
            map_element "name", to: :name
            map_element "eMail", to: :e_mail
            map_element "phone", to: :phone
            map_element "fax", to: :fax
            map_element "location", to: :location
            map_element "descriptionData", to: :description_data
          end
        end
      end
    end
  end
end
