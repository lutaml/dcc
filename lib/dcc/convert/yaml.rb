# frozen_string_literal: true

require "yaml"

module Dcc
  module Convert
    # `Dcc::Convert::Yaml` serializes a parsed DCC to YAML using
    # lutaml-model's framework-provided `to_hash`.
    module Yaml
      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Convert::Result]
        def call(dcc)
          ::Dcc::Convert::Result.new(
            format: :yaml,
            payload: ::YAML.dump(dcc.to_hash),
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end
      end
    end
  end
end