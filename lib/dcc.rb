# frozen_string_literal: true

require "lutaml/model"
require "lutaml/xml"
require "mml"

Lutaml::Model::Config.xml_adapter_type = :nokogiri

# Top-level namespace for the dcc gem.
#
# Dcc provides a fully typed Ruby object model for PTB Digital Calibration
# Certificates (DCC) and D-SI quantity documents. See README.adoc for an
# overview and QUICKSTART.
module Dcc
  SUPPORTED_VERSIONS = [2, 3].freeze

  # Sentinel value used to distinguish "no context supplied" from "context
  # supplied as nil". Defined eagerly so callers can reference it without
  # triggering autoload.
  UNSPECIFIED_CONTEXT = Object.new.freeze

  autoload :VERSION, "dcc/version"
  # Errors are eagerly required so `Dcc::ParseError` etc. are always
  # available without triggering autoload on first reference.
  require "dcc/error"

  autoload :Namespace, "dcc/namespace"
  autoload :Type, "dcc/type"
  autoload :ContextConfiguration, "dcc/context_configuration"
  autoload :ContextOptions, "dcc/context_options"
  autoload :VersionedParser, "dcc/versioned_parser"
  autoload :CommonElements, "dcc/common_elements"
  autoload :Base, "dcc/base"
  autoload :Schema, "dcc/schema"
  autoload :Builder, "dcc/builder"
  autoload :Convert, "dcc/convert"
  autoload :Diff, "dcc/diff"
  autoload :Extract, "dcc/extract"
  autoload :Inspect, "dcc/inspect"
  autoload :Migrate, "dcc/migrate"
  autoload :QuantityFormat, "dcc/quantity_format"
  autoload :QuantityMath, "dcc/quantity_math"
  autoload :Signature, "dcc/signature"
  autoload :Transform, "dcc/transform"
  autoload :Validate, "dcc/validate"
  autoload :Server, "dcc/server"
  autoload :I18n, "dcc/i18n"
  autoload :Plugin, "dcc/plugin"
  autoload :TypeGuards, "dcc/type_guards"
  autoload :Si, "dcc/si"

  autoload :V2, "dcc/v2"
  autoload :V3, "dcc/v3"

  module Cli
    autoload :Cli, "dcc/cli/cli"
  end

  class << self
    # Parse a DCC XML document and return a typed object tree.
    #
    # @param input [String, IO] XML string or readable IO.
    # @param version [Integer, nil] Major DCC version (2 or 3). Auto-detected
    #   from the `schemaVersion` attribute when nil.
    # @param context [Symbol, nil] Substitution context (e.g. `:dcc_v3_4`).
    # @param register [Symbol, nil] Alias for `context` (mml-compatible API).
    # @return [Dcc::V2::DigitalCalibrationCertificate, Dcc::V3::DigitalCalibrationCertificate]
    def parse(input, version: nil, context: nil, register: nil)
      load_all!
      resolved = version || detect_version(input)
      parser_for(resolved).parse(input, context: context, register: register)
    end

    # Build a new DCC programmatically using the builder DSL.
    # @yield [Dcc::Builder::Session] builder session
    # @param version [Integer, nil] major DCC version (default: 3).
    def build(version: 3, &)
      Builder.call(version: version, &)
    end

    # Load plugin gems by name.
    #
    # A gem name maps to its entry file the usual way: "dcc-audit" loads
    # "dcc/audit". A slash-separated path is accepted unchanged.
    #
    # @param names [Array<String, Symbol>] plugin gem names.
    # @raise [Dcc::PluginError] if a plugin's entry file cannot be loaded.
    # @return [Array<String>] the entry-file path for each name given.
    #   A plugin already loaded is left alone and its path still returned.
    #
    # A plugin whose own `require` fails raises from inside a file we did
    # find. Reporting that as a missing entry file points the author at the
    # wrong problem, so only the entry path's own LoadError is wrapped.
    def load_plugins(*names)
      names.flatten.map do |name|
        path = plugin_path(name)
        require path
        path
      rescue ::LoadError => e
        raise unless e.path == path

        raise PluginError, "could not load plugin #{name}: tried " \
                           "require #{path.inspect} (#{e.message})"
      end
    end

    # "dcc-audit" is a gem name and maps to "dcc/audit". Anything already
    # carrying a slash is a require path and is left alone, hyphens included.
    def plugin_path(name)
      text = name.to_s
      text.include?("/") ? text : text.tr("-", "/")
    end
    private :plugin_path

    # Migrate a DCC from one schema version to another.
    #
    # Prefer passing the source XML. A parsed model has to be serialized back
    # to XML before the transform runs, so anything the model could not
    # round-trip is already gone and cannot be migrated or reported.
    #
    # @param input [String, IO, Dcc::V2::DigitalCalibrationCertificate,
    #   Dcc::V3::DigitalCalibrationCertificate] DCC source XML, or a parsed DCC.
    # @param from [String] source version, e.g. "2.3.0".
    # @param to [String] target version, e.g. "3.3.0".
    # @param on_loss [#call, nil] callable receiving each message describing a
    #   construct the migration changed or discarded (a String per loss).
    #   When given, the messages go to the callable and nothing is sent to
    #   `Kernel.warn`; when nil (the default), each loss report is warned to
    #   stderr as before.
    # @return [Dcc::V2::DigitalCalibrationCertificate,
    #   Dcc::V3::DigitalCalibrationCertificate] always a parsed DCC.
    def migrate(input, from:, to:, on_loss: nil)
      Migrate.call(input, from: from, to: to, on_loss: on_loss)
    end

    # Return the parser module for the given major version.
    # @param version [Integer] 2 or 3.
    # @return [Module] Dcc::V2 or Dcc::V3.
    def parser_for(version)
      case version.to_i
      when 2 then V2
      when 3 then V3
      else
        raise UnknownVersionError,
              "Unsupported DCC version: #{version.inspect} (expected 2 or 3)"
      end
    end

    # Detect the DCC major version from an XML document's `schemaVersion` attribute.
    # @param input [String, IO]
    # @return [Integer] 2 or 3.
    def detect_version(input)
      str = read_input(input)
      match = str.match(/schemaVersion\s*=\s*["'](\d+)\./)
      major = match && match[1] ? match[1].to_i : 3
      major == 2 ? 2 : 3
    end

    # Read an input that may be a String or an IO-like object.
    # Uses explicit type checks per project rule (no `respond_to?`).
    # @param input [String, IO, StringIO, File, Tempfile]
    # @return [String]
    def read_input(input)
      return input.read if io_like?(input)

      input.to_s
    end

    # @return [Boolean] whether the input is an IO-like stream we support.
    def io_like?(input)
      !!(input.is_a?(::IO) ||
        input.is_a?(::StringIO) ||
        input.is_a?(::File) ||
        (defined?(::Tempfile) && input.is_a?(::Tempfile)))
    end

    # Eager-load every version context (DCC + D-SI) so symbol type
    # references in the base modules resolve correctly. Called automatically
    # on first `Dcc.parse`. Safe to call multiple times.
    # @return [true]
    def load_all!
      V2.load_all!
      V3.load_all!
      Si::V1.load_all!
      Si::V2.load_all!
      true
    end
  end
end
