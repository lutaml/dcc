# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Type
    # ISO 3166-1 alpha-2 country code (two uppercase letters, e.g. `"DE"`).
    # Used by `dcc:countryCodeISO3166_1`.
    class IsoCountryCode < Lutaml::Model::Type::String
      PATTERN = /\A[A-Z]{2}\z/.freeze

      def self.cast(value)
        return nil unless value.is_a?(::String) && value != ""

        unless PATTERN.match?(value)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "invalid ISO 3166-1 alpha-2 country code: #{value.inspect}")
        end

        value
      end
    end
  end
end
