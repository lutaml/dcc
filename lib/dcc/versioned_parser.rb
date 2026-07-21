# frozen_string_literal: true

# `Dcc::VersionedParser` is mixed into each major-version module
# (`Dcc::V2`, `Dcc::V3`, `Dcc::Si::V1`, `Dcc::Si::V2`) to provide a uniform
# `.parse(input, context:, register:)` entry point that delegates to
# `Lutaml::Model::GlobalContext` for type resolution.
#
# The version module must:
# 1. `extend Dcc::VersionedParser`
# 2. Define `self::ROOT_ELEMENT_TAG` — the XML element name to resolve
#    (e.g. `"digitalCalibrationCertificate"`).
# 3. Define `self::Configuration` — a module that extends
#    `Dcc::ContextConfiguration` and declares `CONTEXT_ID`.
module Dcc
  module VersionedParser
    # Parse an XML document into the version's typed object tree.
    #
    # @param input [String, IO] XML string or readable IO.
    # @param context [Symbol, String, nil] substitution context.
    # @param register [Symbol, String, nil] deprecated alias for `context`.
    # @return [Lutaml::Model::Serializable] parsed root element.
    def parse(input, context: ::Dcc::UNSPECIFIED_CONTEXT, register: nil)
      context_id = resolve_context_id(context, register)
      root_class = Lutaml::Model::GlobalContext.resolve_type(
        root_element_symbol,
        context_id,
      )

      xml = ::Dcc.read_input(input)
      root_class.from_xml(xml, register: context_id)
    end

    private

    def resolve_context_id(context, register)
      ::Dcc::ContextOptions.normalize_context_option(
        context: context,
        register: register,
        default_context: self::Configuration.default_context_id,
        warning_source: "#{name}.parse",
      )
    end

    def root_element_symbol
      self.const_get(:ROOT_ELEMENT_TAG).to_sym
    end
  end
end
