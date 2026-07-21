# frozen_string_literal: true

require "open3"

module Dcc
  module Transform
    # `Dcc::Transform::Xslt` applies an XSLT stylesheet to a DCC XML document.
    #
    # Nokogiri is OFFICIALLY banned outside validation, so we shell out to
    # the system `xsltproc` (libxslt) for XSLT 1.0 transforms. For XSLT
    # 2.0/3.0, set `ENV["SAXON_JAR"]` to point at saxon-he.jar.
    module Xslt
      class << self
        # @param xml [String, Lutaml::Model::Serializable]
        # @param stylesheet [String] path to XSLT file or raw XSLT.
        # @param engine [Symbol] :xsltproc (default) or :saxon.
        # @return [Dcc::Transform::Result]
        def call(xml, stylesheet, engine: :xsltproc)
          xml_string = xml.is_a?(::String) ? xml : xml.to_xml
          output = case engine
                   when :xsltproc then run_xsltproc(xml_string, stylesheet)
                   when :saxon then run_saxon(xml_string, stylesheet)
                   else
                     raise ::ArgumentError, "unknown XSLT engine: #{engine.inspect}"
                   end
          ::Dcc::Transform::Result.new(payload: output, engine: engine)
        end

        private

        def run_xsltproc(xml, stylesheet)
          ensure_tool!("xsltproc")
          xsl_path = stylesheet_path(stylesheet)
          out, status = ::Open3.capture2("xsltproc", xsl_path, "-", stdin_data: xml)
          raise ::Dcc::TransformError, "xsltproc failed: #{status}" unless status.success?

          out
        end

        def run_saxon(xml, stylesheet)
          jar = ENV["SAXON_JAR"]
          raise ::Dcc::MissingDependencyError.new(gem_name: "saxon-he",
                                                  feature: "XSLT 2.0/3.0"),
                "SAXON_JAR env var is required for the :saxon engine" unless jar

          xsl_path = stylesheet_path(stylesheet)
          cmd = ["java", "-jar", jar, "-s:-", "-xsl:#{xsl_path}"]
          out, status = ::Open3.capture2(*cmd, stdin_data: xml)
          raise ::Dcc::TransformError, "saxon failed: #{status}" unless status.success?

          out
        end

        def stylesheet_path(stylesheet)
          return stylesheet if File.exist?(stylesheet)

          Tempfile.create(["dcc-transform", ".xsl"]) do |f|
            f.write(stylesheet)
            f.path
          end
        end

        def ensure_tool!(name)
          return if system("which #{name} > /dev/null 2>&1")

          raise ::Dcc::MissingDependencyError.new(gem_name: name, feature: "Dcc::Transform"),
                "#{name} CLI not available on PATH"
        end
      end
    end
  end
end