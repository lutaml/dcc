# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:identificationType` — single identifier (issuer, value, optional
    # description). Issuer enum: manufacturer, calibrationLaboratory, customer,
    # owner, other.
    module Identification
      def self.included(klass)
        klass.class_eval do
          attribute :issuer, :string
          attribute :value, :string
          attribute :description, :text

          xml do
            namespace ::Dcc::Namespace::Dcc
            element "identification"
            ordered
            map_element "issuer", to: :issuer
            map_element "value", to: :value
            map_element "description", to: :description
          end
        end
      end
    end
  end
end
