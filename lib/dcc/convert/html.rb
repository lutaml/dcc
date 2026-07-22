# frozen_string_literal: true

require "liquid"

module Dcc
  module Convert
    module Html
      TEMPLATE_PATH = File.expand_path("templates/report.liquid", __dir__).freeze

      class << self
        def call(dcc, lang: nil)
          hash = ::Dcc::Convert::Json.xml_to_hash(dcc.to_xml)
          rendered = render_template(hash, lang: lang)
          ::Dcc::Convert::Result.new(
            format: :html,
            payload: rendered,
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
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
