# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Type
    # DCC `schemaVersion` attribute (e.g. `"3.3.0"`, `"3.4.0-rc.2"`).
    # Validates the format on cast. Use `Dcc::Schema::Version.major(v)` to
    # extract the major number from any version string.
    class SchemaVersion < Lutaml::Model::Type::String
      PATTERN = /\A
        (?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)
        (?:-(?<pre>[0-9A-Za-z.-]+))?
        (?:\+(?<build>[0-9A-Za-z.-]+))?
      \z/x.freeze

      def self.cast(value)
        return nil unless value.is_a?(::String) && value != ""

        unless PATTERN.match?(value)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "invalid schemaVersion")
        end

        value
      end

      def major
        self.class.extract_major(to_s)
      end

      def self.extract_major(value)
        m = PATTERN.match(value.to_s)
        m && Integer(m[:major])
      end
    end
  end
end
