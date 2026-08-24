# frozen_string_literal: true

require "thor"

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

      desc "validate SCHEMA FILE",
           "Validate a DCC XML against XSD, Schematron, or both"
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
          when "xsd"        then ::Dcc::Validate::Xsd.call(xml,
                                                           version: version)
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

      desc "convert FORMAT FILE",
           "Convert a DCC XML file to json / yaml / csv / html"
      method_option :output, type: :string, banner: "PATH",
                             desc: "Write output to a file instead of stdout"
      def convert(format, file)
        Cli.ensure_loaded!
        xml = File.read(file)
        result =
          case format
          when "json" then ::Dcc::Convert::Json.call(Dcc.parse(xml))
          when "yaml" then ::Dcc::Convert::Yaml.call(Dcc.parse(xml))
          when "html" then ::Dcc::Convert::Html.call(xml)
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

      desc "extract TARGET FILE",
           "Extract embedded files or formulae from a DCC"
      method_option :index, type: :numeric, desc: "Index of the file to extract"
      method_option :output, type: :string, banner: "PATH",
                             desc: "Write extracted payload to PATH"
      method_option :ring, type: :string,
                           enum: %w[administrativeData measurementResults comment document]
      # `repeatable` and not `type: :array`: with an array type Thor lets a
      # second `-v` overwrite the first, so `-v T=42 -v R0=1` would silently
      # drop T. PTB's CLI accumulates, and so must this.
      method_option :variable, type: :string, aliases: "-v", repeatable: true,
                               banner: "NAME=VALUE",
                               desc: "Override a formula variable (repeatable; NAME=V1,V2 for a list)"
      def extract(target, file)
        Cli.ensure_loaded!
        dcc = Dcc.parse(File.read(file))
        case target
        when "files" then extract_files(dcc)
        when "formulae" then extract_formulae(dcc)
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

      desc "serve", "Start the DCC web validator (http://localhost:4567)"
      method_option :port, type: :numeric, default: 4567, desc: "Port"
      method_option :bind, type: :string, default: "0.0.0.0",
                           desc: "Bind address"
      def serve
        require "dcc/server"
        ::Dcc.load_all!
        puts "Starting DCC Validator on http://localhost:#{options[:port]}"
        ::Dcc::Server::App.run!(port: options[:port], bind: options[:bind])
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

        def extract_files(dcc)
          files = ::Dcc::Extract::File.each(dcc)
          if options[:ring]
            files = files.select { |f| f.ring.to_s == options[:ring] }
          end
          return ::Dcc::Cli::Formatters.print_files(files) unless options[:index]

          index = options[:index].to_i
          file = files[index] || abort("No file at index #{index}")
          output_to(file.data, options[:output], file.file_name)
        end
      end

      no_commands do
        def extract_formulae(dcc)
          variables = parse_variables(options[:variable])
          formulae = ::Dcc::Extract::Formula.call(dcc)
          check_overrides(formulae, variables)
          print_formulae(formulae, variables)
        rescue ::Dcc::ExtractionError => e
          abort e.message
        end

        # The evaluator slices bindings down to the names a formula
        # actually references, so a mistyped -v reaches nothing and the
        # run still reports success with plausible default numbers.
        # `decimal_or_abort` already aborts on a malformed -v; an
        # override that lands nowhere is the same class of mistake.
        def check_overrides(formulae, variables)
          unknown = variables.keys - formulae.flat_map(&:variables)
          return if unknown.empty?

          abort "No formula references #{unknown.join(', ')}"
        end
      end

      no_commands do
        def parse_variables(assignments)
          Array(assignments).each_with_object({}) do |assignment, variables|
            name, values = split_assignment(assignment)
            variables[name] = override_value(values)
          end
        end

        # `-v T=42` is a scalar and broadcasts across the document's lists;
        # only `-v T=1,2` is a list, and a list has to match every other
        # list's length. Wrapping a lone value in an array made `-v R0=1`
        # a one-element list that collided with the document's own.
        def override_value(values)
          decimals = values.map { |v| decimal_or_abort(v) }
          decimals.size == 1 ? decimals.first : decimals
        end
      end

      no_commands do
        # `split(",", -1)` keeps trailing empty fields, so `T=42,` reaches
        # validation instead of silently losing the empty entry.
        def split_assignment(assignment)
          name, values = assignment.split("=", 2)
          if name.nil? || name.empty? || values.nil? || values.empty?
            abort "#{assignment} is not a valid NAME=value"
          end

          [name, values.split(",", -1)]
        end

        # Validated here, at the command line, not where the value is used.
        # The evaluator only coerces variables the formula references, so a
        # bad `-v` for an unreferenced variable — or any `-v` against a
        # document with no formulae — would otherwise pass in silence.
        #
        # Delegates rather than calling BigDecimal itself: a second
        # coercion site is exactly the drift the single boundary exists to
        # prevent, even when it starts out agreeing.
        def decimal_or_abort(value)
          ::Dcc::Extract::Formula::Quantity.decimal(value)
        rescue ::Dcc::ExtractionError
          abort "#{value} is not a valid decimal value"
        end
      end

      no_commands do
        def print_formulae(formulae, variables)
          return puts("No formulae found.") if formulae.empty?

          # `map`, deliberately, not `all?` with a block: `all?`
          # short-circuits, and stopping at the first failure is exactly
          # the bug this is fixing.
          printed = formulae.map { |formula| print_formula(formula, variables) }
          exit(1) unless printed.all?
        end
      end

      no_commands do
        # Evaluates before printing the header. A header printed ahead
        # of a failure leaves a truncated record on stdout that reads
        # like a formula with no values. One formula that cannot be
        # evaluated is reported on stderr and the rest still print.
        def print_formula(formula, variables)
          values = formula.evaluate(variables)
          puts formula
          values.each { |value| puts "  #{value.to_s('F')}" }
          true
        rescue ::Dcc::ExtractionError => e
          # `$stderr.puts`, not `warn`: Kernel#warn prints nothing when
          # warnings are off, so `RUBYOPT=-W0` would leave the user with
          # exit 1 and no explanation at all. The cop's own rationale —
          # "to allow such output to be disabled" — is the thing this
          # message must not permit.
          $stderr.puts "#{formula}: #{e.message}" # rubocop:disable Style/StderrPuts
          false
        end
      end
    end
  end
end
