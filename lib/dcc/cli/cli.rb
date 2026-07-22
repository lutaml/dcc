# frozen_string_literal: true

require "thor"
require "tty-table"

# `Dcc::Cli::Cli` is the Thor-based command-line interface. Each subcommand
# (validate, convert, extract, signature, transform, inspect, diff, issue)
# corresponds to a feature service exposed by the gem.
module Dcc
  module Cli
    autoload :Formatters, "dcc/cli/formatters"

    class Cli < Thor
      package_name "dcc"

      class << self
        # Lazy-load the model contexts the first time a CLI command runs.
        # This avoids autoload side effects when users just want the gem
        # library (no CLI).
        def ensure_loaded!
          ::Dcc::V3.load_all!
          ::Dcc::V2.load_all!
        end
      end

      def self.exit_on_failure?
        true
      end

      desc "validate SCHEMA FILE", "Validate a DCC XML against XSD, Schematron, or both"
      long_desc <<~DESC
        Validates the given DCC XML file.

        Examples:
          $ dcc validate xsd cert.xml
          $ dcc validate schematron cert.xml
          $ dcc validate all cert.xml
      DESC
      method_option :version, type: :string, default: "auto",
                    desc: "Schema version (e.g. '3.3.0', 'auto')"
      method_option :format, type: :string, default: "text",
                    enum: %w[text json yaml]
      def validate(schema, file)
        Cli.ensure_loaded!
        xml = File.read(file)
        version = options[:version]
        result =
          case schema
          when "xsd"        then ::Dcc::Validate::Xsd.call(xml, version: version)
          when "schematron" then ::Dcc::Validate::Schematron.call(Dcc.parse(xml))
          when "all"
            ::Dcc::Validate::Xsd.call(xml, version: version)
                   .merge(::Dcc::Validate::Schematron.call(Dcc.parse(xml)))
          else
            abort "Unknown validation target: #{schema} (expected xsd|schematron|all)"
          end
        ::Dcc::Cli::Formatters.print(result, format: options[:format])
        exit(1) unless result.ok?
      end

      desc "convert FORMAT FILE", "Convert a DCC XML file to json / yaml / csv / html"
      method_option :output, type: :string, banner: "PATH",
                    desc: "Write output to a file instead of stdout"
      def convert(format, file)
        Cli.ensure_loaded!
        xml = File.read(file)
        dcc = Dcc.parse(xml)
        result =
          case format
          when "json" then ::Dcc::Convert::Json.call(dcc)
          when "yaml" then ::Dcc::Convert::Yaml.call(dcc)
          when "html" then ::Dcc::Convert::Html.call(dcc)
          else
            abort "Format not yet implemented: #{format}"
          end
        output = result.to_s
        if options[:output]
          File.write(options[:output], output)
        else
          $stdout.puts(output)
        end
      end

      desc "extract TARGET FILE", "Extract embedded files or quantities from a DCC"
      method_option :index, type: :numeric, desc: "Index of the file to extract"
      method_option :output, type: :string, banner: "PATH",
                    desc: "Write extracted payload to PATH"
      method_option :ring, type: :string,
                    enum: %w[administrativeData measurementResults comment document]
      def extract(target, file)
        Cli.ensure_loaded!
        dcc = Dcc.parse(File.read(file))
        case target
        when "files"
          files = ::Dcc::Extract::File.each(dcc)
          files = files.select { |f| f.ring.to_s == options[:ring] } if options[:ring]
          if options[:index]
            f = files[options[:index].to_i] || abort("No file at index #{options[:index]}")
            output_to(f.data, options[:output], f.file_name)
          else
            ::Dcc::Cli::Formatters.print_files(files)
          end
        else
          abort "Unknown extract target: #{target}"
        end
      end

      desc "inspect FILE", "Show a human-readable summary of a DCC"
      method_option :format, type: :string, default: "text",
                    enum: %w[text json yaml]
      def inspect(file)
        Cli.ensure_loaded!
        dcc = Dcc.parse(File.read(file))
        report = ::Dcc::Inspect::Report.call(dcc)
        ::Dcc::Cli::Formatters.print(report, format: options[:format])
      end

      desc "diff FILE1 FILE2", "Compare two DCC files structurally"
      method_option :format, type: :string, default: "text",
                    enum: %w[text json]
      def diff(file1, file2)
        Cli.ensure_loaded!
        dcc1 = Dcc.parse(File.read(file1))
        dcc2 = Dcc.parse(File.read(file2))
        diff = ::Dcc::Diff.call(dcc1, dcc2)
        ::Dcc::Cli::Formatters.print(diff, format: options[:format])
      end

      desc "version", "Print the dcc gem version"
      def version
        puts "dcc #{::Dcc::VERSION}"
      end

      no_commands do
        def output_to(payload, path, file_name)
          if path
            File.binwrite(path, payload)
            say "Wrote #{payload.bytesize} bytes to #{path}"
          elsif file_name
            File.binwrite(file_name, payload)
            say "Wrote #{payload.bytesize} bytes to #{file_name}"
          else
            $stdout.binmode
            $stdout.write(payload)
          end
        end
      end
    end
  end
end