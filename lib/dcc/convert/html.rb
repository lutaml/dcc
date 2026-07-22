# frozen_string_literal: true

module Dcc
  module Convert
    # `Dcc::Convert::Html` renders a parsed DCC into a human-readable HTML
    # report with collapsible sections per administrative section and
    # measurement result.
    module Html
      class << self
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Dcc::Convert::Result]
        def call(dcc)
          payload = <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <title>DCC Report #{escape(unique_identifier_of(dcc))}</title>
              <style>
                body { font-family: -apple-system, system-ui, sans-serif; margin: 2rem; }
                h1, h2, h3 { color: #333; }
                section { margin-bottom: 1.5rem; padding: 1rem; border: 1px solid #eee; border-radius: 4px; }
                table { border-collapse: collapse; }
                th, td { border: 1px solid #ddd; padding: 0.5rem 1rem; text-align: left; }
                th { background: #f5f5f5; }
              </style>
            </head>
            <body>
              <h1>Digital Calibration Certificate</h1>
              #{summary_table(dcc)}
              #{administrative_section(dcc)}
              #{measurement_section(dcc)}
            </body>
            </html>
          HTML

          ::Dcc::Convert::Result.new(
            format: :html,
            payload: payload,
            source_class: dcc.class.name,
            schema_version: dcc.schema_version.to_s,
          )
        end

        private

        def summary_table(dcc)
          <<~HTML
            <section>
              <h2>Identity</h2>
              <table>
                <tr><th>Schema version</th><td>#{escape(dcc.schema_version)}</td></tr>
                <tr><th>Unique identifier</th><td>#{escape(unique_identifier_of(dcc))}</td></tr>
                <tr><th>Country</th><td>#{escape(country_of(dcc))}</td></tr>
              </table>
            </section>
          HTML
        end

        def administrative_section(dcc)
          return "" unless Dcc::TypeGuards.has_attribute?(dcc, :administrative_data) && dcc.administrative_data

          admin = dcc.administrative_data
          items = Dcc::TypeGuards.has_attribute?(admin, :items) && admin.items ? Array(admin.items.item) : []
          <<~HTML
            <section>
              <h2>Items (#{items.size})</h2>
              <ul>
                #{items.map { |i| "<li>#{escape(name_of(i))}</li>" }.join("\n")}
              </ul>
            </section>
          HTML
        end

        def measurement_section(dcc)
          return "" unless Dcc::TypeGuards.has_attribute?(dcc, :measurement_results) && dcc.measurement_results

          mrs = Array(dcc.measurement_results.measurement_result)
          <<~HTML
            <section>
              <h2>Measurement Results (#{mrs.size})</h2>
              <ul>
                #{mrs.map { |mr| "<li>#{escape(name_of(mr))}</li>" }.join("\n")}
              </ul>
            </section>
          HTML
        end

        def unique_identifier_of(dcc)
          Dcc::TypeGuards.has_attribute?(dcc, :administrative_data) &&
            Dcc::TypeGuards.has_attribute?(dcc.administrative_data, :core_data) &&
            dcc.administrative_data.core_data &&
            dcc.administrative_data.core_data.unique_identifier.to_s
        end

        def country_of(dcc)
          Dcc::TypeGuards.has_attribute?(dcc, :administrative_data) &&
            Dcc::TypeGuards.has_attribute?(dcc.administrative_data, :core_data) &&
            dcc.administrative_data.core_data &&
            dcc.administrative_data.core_data.country_code_iso_3166_1.to_s
        end

        def name_of(node)
          return "" unless node && Dcc::TypeGuards.has_attribute?(node, :name)
          return "" unless node.name

          content = Dcc::TypeGuards.has_attribute?(node.name, :content) ? node.name.content : []
          first = Array(content).first
          return "" unless first

          vals = Dcc::TypeGuards.has_attribute?(first, :value) ? first.value : []
          Array(vals).first.to_s
        end

        def escape(s)
          return "" if s.nil?

          s.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
      end
    end
  end
end