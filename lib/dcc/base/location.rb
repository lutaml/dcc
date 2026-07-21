# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:locationType` — physical address. Choice of `city`, `countryCode`,
    # `postCode`, `postOfficeBox`, `state`, `street`, `streetNo`, `further`.
    module Location
      def self.included(klass)
        klass.class_eval do
          attribute :city, :string
          attribute :country_code, :string
          attribute :post_code, :string
          attribute :post_office_box, :string
          attribute :state, :string
          attribute :street, :string
          attribute :street_no, :string
          attribute :further, :string

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "location"
            ordered
            map_element "city", to: :city
            map_element "countryCode", to: :country_code
            map_element "postCode", to: :post_code
            map_element "postOfficeBox", to: :post_office_box
            map_element "state", to: :state
            map_element "street", to: :street
            map_element "streetNo", to: :street_no
            map_element "further", to: :further
          end
        end
      end
    end
  end
end
