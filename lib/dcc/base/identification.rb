# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:identificationType` — single identifier (issuer, value, optional
    # name). Issuer enum: manufacturer, calibrationLaboratory, customer,
    # owner, other.
    #
    # v3 calls the third child `name`; v2 calls it `description`, which
    # `Dcc::V2::Identification` maps.
    module Identification
      def self.included(klass)
        klass.class_eval do
          attribute :issuer, :string
          attribute :value, :string
          attribute :name, :text

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "identification"
            ordered
            map_element "issuer", to: :issuer
            map_element "value", to: :value
            map_element "name", to: :name
          end
        end
      end
    end
  end
end
