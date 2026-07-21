# frozen_string_literal: true

require "lutaml/model"

module Dcc
  module Type
    # D-SI unit expression in siunitx notation (e.g. `"\kelvin"`,
    # `"\meter\per\second\squared"`). The full siunitx grammar is enforced by
    # the D-SI ontology's SHACL profile; here we apply a lightweight syntactic
    # check: the string must not contain whitespace (Schematron rule), and the
    # non-SI declaration prefix (`|unit`) is allowed.
    class SiUnit < Lutaml::Model::Type::String
      NO_WHITESPACE_PATTERN = /\A\S+\z/.freeze

      def self.cast(value)
        return nil unless value.is_a?(::String) && value != ""

        unless NO_WHITESPACE_PATTERN.match?(value)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "invalid SI unit expression (whitespace not allowed): #{value.inspect}")
        end

        value
      end
    end
  end
end
