# frozen_string_literal: true

require "json"

module Dcc
  module Convert
    # `Dcc::Convert::Json` serializes a parsed DCC to JSON by converting
    # the `to_xml` output to a JSON-compatible hash.
    module Json
      class << self
        def call(dcc, pretty: true)
          hash = xml_to_hash(dcc.to_xml)
          payload = pretty ? ::JSON.pretty_generate(hash) : ::JSON.generate(hash)
          ::Dcc::Convert::Result.new(
            format: :json,
            payload: payload,
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end

        def xml_to_hash(xml_string)
          doc = ::Lutaml::Model::Config.xml_adapter.parse(xml_string)
          element_to_hash(doc.root)
        end

        private

        def element_to_hash(element)
          hash = {}

          element.attributes&.each do |k, v|
            hash[k.to_s] = v.value.to_s
          end

          children = element.children.to_a.reject(&:text?)
          text_children = element.children.to_a.select(&:text?)
          combined_text = text_children.map(&:text).join.strip

          if children.empty?
            return combined_text if hash.empty? && !combined_text.empty?
            return hash if combined_text.empty?

            hash["_text"] = combined_text
            return hash
          end

          children.each do |child|
            name = child.name.to_s.split(":").last
            value = element_to_hash(child)
            if hash.key?(name)
              hash[name] = Array(hash[name]) << value
            else
              hash[name] = value
            end
          end
          hash
        end
      end
    end
  end
end