# frozen_string_literal: true

require "yaml"

module Dcc
  module Convert
    module Yaml
      class << self
        def call(dcc)
          hash = ::Dcc::Convert::Json.xml_to_hash(dcc.to_xml)
          ::Dcc::Convert::Result.new(
            format: :yaml,
            payload: ::YAML.dump(hash),
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end
      end
    end
  end
end