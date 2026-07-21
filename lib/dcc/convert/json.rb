# frozen_string_literal: true

require "json"

module Dcc
  module Convert
    # `Dcc::Convert::Json` serializes a parsed DCC object tree to JSON using
    # lutaml-model's framework-provided `to_hash` / `to_json` methods. We
    # never hand-roll `to_json` on model classes (per global rule).
    #
    # @example
    #   json_doc = Dcc::Convert::Json.call(dcc)
    #   json_doc.to_s          # the JSON string
    #   json_doc.format        # :json
    #   json_doc.parsed        # parsed Ruby structure
    module Json
      class << self
        # @param dcc [Lutaml::Model::Serializable] the parsed DCC object.
        # @param pretty [Boolean] human-readable formatting.
        # @return [Dcc::Convert::Result]
        def call(dcc, pretty: true)
          payload = pretty ? ::JSON.pretty_generate(dcc.to_hash) : ::JSON.generate(dcc.to_hash)
          ::Dcc::Convert::Result.new(
            format: :json,
            payload: payload,
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end
      end
    end
  end
end