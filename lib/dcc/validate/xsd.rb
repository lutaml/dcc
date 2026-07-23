# frozen_string_literal: true

require "nokogiri"

module Dcc
  module Validate
    # `Dcc::Validate::Xsd` validates DCC XML against one of the 12 bundled DCC
    # schema versions. Auto-detects the version from the `schemaVersion`
    # attribute when `version:` is `:auto` or nil.
    #
    # @example
    #   result = Dcc::Validate::Xsd.call(File.read("certificate.xml"))
    #   result.ok?      # => true
    #   result.errors   # => []
    #
    #   result = Dcc::Validate::Xsd.call(xml, version: "3.3.0")
    #   result = Dcc::Validate::Xsd.call(xml, version: :auto)
    module Xsd
      SCHEMA_CACHE = {} # rubocop:disable Style/MutableConstant -- populated at runtime

      class << self
        # @param xml [String, IO] DCC XML to validate.
        # @param version [String, Symbol, nil] DCC version or `:auto` for
        #   auto-detection. Defaults to `:auto`.
        # @return [Dcc::Validate::Result]
        def call(xml, version: :auto)
          resolved = ::Dcc::Schema::Version.resolve_dcc(version, xml: xml)
          schema = schema_for(resolved)
          doc = parse_xml(xml)
          errors = schema.validate(doc).map { |e| issue_from_nokogiri(e, resolved) }

          ::Dcc::Validate::Result.new(
            issues: errors,
            schema_version: resolved,
            source: "xsd",
          )
        end

        private

        def schema_for(version)
          SCHEMA_CACHE[version] ||= load_schema(version)
        end

        def load_schema(version)
          xsd_path = ::Dcc::Schema.path("dcc/v#{version}/dcc.xsd")
          resolved = resolve_imports(xsd_path)
          ::Nokogiri::XML::Schema.new(resolved)
        rescue ::Nokogiri::XML::SyntaxError => e
          raise ::Dcc::SchemaError,
                "Failed to load bundled DCC XSD v#{version}: #{e.message}",
                e.backtrace
        end

        # Rewrite relative `schemaLocation` imports to absolute file:// URIs
        # so libxml2 can resolve them regardless of the process CWD. Nokogiri
        # does not expose a base-URI option for `Schema.new`.
        def resolve_imports(xsd_path)
          base_dir = ::File.dirname(xsd_path)
          content = ::File.read(xsd_path)
          content.gsub(/schemaLocation\s*=\s*"([^"]+)"/) do |_match|
            relative = ::Regexp.last_match(1)
            next %{schemaLocation="#{relative}"} if relative.start_with?("http", "file://")

            absolute = ::File.expand_path(relative, base_dir)
            uri_path = absolute.gsub(::File::ALT_SEPARATOR || "\\", "/")
            uri_path = "/#{uri_path}" unless uri_path.start_with?("/")
            %{schemaLocation="file://#{uri_path}"}
          end
        end

        def parse_xml(xml)
          xml_string = ::Dcc.read_input(xml)
          ::Nokogiri::XML(xml_string) { |c| c.strict }
        end

        def issue_from_nokogiri(nokogiri_error, version)
          ::Dcc::Validate::Issue.build(
            severity: classify(nokogiri_error),
            message: nokogiri_error.message,
            code: "dcc.xsd.#{version}",
            line: nokogiri_error.line,
            column: nokogiri_error.column,
            source: "xsd",
          )
        end

        def classify(nokogiri_error)
          # libxml2 levels: 1 = WARNING, 2 = ERROR, 3 = FATAL.
          case nokogiri_error.level
          when 2, 3 then ::Dcc::Validate::Severity::ERROR
          when 1 then ::Dcc::Validate::Severity::WARNING
          else ::Dcc::Validate::Severity::INFO
          end
        end
      end
    end
  end
end
