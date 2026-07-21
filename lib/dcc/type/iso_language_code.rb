# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Type
    # ISO 639-1 language code (two lowercase letters, e.g. `"en"`).
    # Used by `dcc:usedLangCodeISO639_1` and `dcc:mandatoryLangCodeISO639_1`.
    class IsoLanguageCode < Lutaml::Model::Type::String
      PATTERN = /\A[a-z]{2}\z/.freeze

      def self.cast(value)
        return nil unless value.is_a?(::String) && value != ""

        unless PATTERN.match?(value)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "invalid ISO 639-1 language code: #{value.inspect}")
        end

        value
      end
    end
  end
end
