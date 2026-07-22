# frozen_string_literal: true

require "rexml/parsers/pullparser"
require "stringio"

module Dcc
  module Streaming
    # Pull-parser-based streaming reader. Yields typed `Dcc::V2::*` /
    # `Dcc::V3::*` objects for matched XML element subtrees without ever
    # materializing the full document.
    #
    # @example
    #   Dcc::Streaming::Reader.each(io, element: "item") do |item|
    #     puts item.name.content.first.value
    #   end
    class Reader
      DEFAULT_NAMESPACES = {
        "dcc" => "https://ptb.de/dcc",
        "si"  => "https://ptb.de/si",
      }.freeze

      class << self
        # Stream-parse an input and yield one typed object per matched
        # element. Use `element:` to pick which element type to stream.
        #
        # @param input [String, IO]
        # @param element [Symbol, String] one of :item, :measurementResult,
        #   :quantity, :result, etc.
        # @param version [Integer, nil] major DCC version (default: auto-detect).
        # @yieldparam [Lutaml::Model::Serializable] a parsed subtree.
        def each(input, element:, version: nil, &block)
          return enum_for(:each, input, element: element, version: version) unless block_given?

          Dcc.load_all!
          xml_string = Dcc.read_input(input)
          detected_version = version || Dcc.detect_version(xml_string)
          target = element.to_s

          parser_module = Dcc.parser_for(detected_version)
          target_class = resolve_class(parser_module, target)

          walk_subtrees(xml_string, target) do |subtree_xml|
            begin
              obj = target_class.from_xml(wrap_with_namespaces(subtree_xml, parser_module))
              yield obj
            rescue StandardError
              next
            end
          end
        end

        private

        def resolve_class(parser_module, element)
          constant_name = element
                         .to_s
                         .gsub(/(?:^|_)([a-z])/) { ::Regexp.last_match(1).upcase }
                         .sub(/\A./) { |c| c.upcase }
          klass = parser_module.const_get(constant_name)
          return klass if klass.is_a?(Class)

          raise ::Dcc::ExtractionError,
                "no wrapper class for element #{element.inspect} in #{parser_module}"
        rescue ::NameError => e
          raise ::Dcc::ExtractionError,
                "no wrapper class for element #{element.inspect}: #{e.message}"
        end

        def walk_subtrees(xml_string, target_element)
          parser = ::REXML::Parsers::PullParser.new(xml_string)
          depth = 0
          buffer = +""
          capturing = false

          while parser.has_next?
            event = parser.pull
            type = event[0]
            case type
            when :start_element
              name = strip_prefix(event[1])
              if !capturing && name == target_element
                capturing = true
                depth = 1
                buffer.clear
                buffer << open_tag(name, event[2])
              elsif capturing
                depth += 1
                buffer << open_tag(name, event[2])
              end
            when :end_element
              name = strip_prefix(event[1])
              if capturing
                buffer << close_tag(name)
                depth -= 1
                if depth.zero?
                  capturing = false
                  yield buffer.dup
                  buffer.clear
                end
              end
            when :text
              next unless capturing

              buffer << escape_text(event[1])
            when :cdata
              next unless capturing

              buffer << "<![CDATA[#{event[1]}]]>"
            end
          end
        end

        def strip_prefix(name)
          name.to_s.split(":").last
        end

        def open_tag(name, attrs)
          attr_str = attrs.to_a.map { |k, v| " #{k}=\"#{escape_attr(v)}\"" }.join
          "<#{name}#{attr_str}>"
        end

        def close_tag(name)
          "</#{name}>"
        end

        def escape_text(text)
          text.to_s
              .gsub("&", "&amp;")
              .gsub("<", "&lt;")
              .gsub(">", "&gt;")
        end

        def escape_attr(value)
          value.to_s.gsub('"', "&quot;")
        end

        def wrap_with_namespaces(xml_fragment, parser_module)
          ns = parser_module::Namespace
          %(<dcc:digitalCalibrationCertificate xmlns:dcc="#{ns.uri}" xmlns:si="https://ptb.de/si" schemaVersion="3.3.0">#{xml_fragment}</dcc:digitalCalibrationCertificate>)
        end
      end
    end
  end
end