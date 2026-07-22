# frozen_string_literal: true

require "liquid"

module Dcc
  module Convert
    module Html
      TEMPLATE_PATH = File.expand_path("templates/report.liquid", __dir__).freeze

      class << self
        def call(dcc_or_xml, lang: nil)
          if dcc_or_xml.is_a?(::String)
            xml = dcc_or_xml
            hash = ::Dcc::Convert::Json.xml_to_hash(xml)
            schema_version = hash["schemaVersion"]
            source_class = "xml"
          else
            xml = dcc_or_xml.to_xml
            hash = ::Dcc::Convert::Json.xml_to_hash(xml)
            schema_version = dcc_or_xml.schema_version.to_s
            source_class = dcc_or_xml.class.name
          end
          rendered = render_template(hash, lang: lang)
          ::Dcc::Convert::Result.new(
            format: :html,
            payload: rendered,
            source_class: source_class,
            schema_version: schema_version,
          )
        end

        private

        def render_template(hash, lang:)
          template = ::Liquid::Template.parse(File.read(TEMPLATE_PATH))
          template.render({ "dcc" => hash, "page_lang" => lang },
                           filters: [::Dcc::Convert::LiquidFilters])
        end
      end
    end
  end
end
