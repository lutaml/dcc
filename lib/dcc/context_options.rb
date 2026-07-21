# frozen_string_literal: true

# `Dcc::ContextOptions` normalizes the `context:` / `register:` options that
# callers can pass to `Dcc.parse`, `Dcc::V3.parse`, etc.
module Dcc
  module ContextOptions
    module_function

    # Collapse the public `context:` and `register:` options into a single
    # context id symbol (or `nil` to fall back to the caller's default).
    #
    # @param context [Symbol, String, nil, Dcc::UNSPECIFIED_CONTEXT]
    # @param register [Symbol, String, nil] deprecated alias for `context:`.
    # @param default_context [Symbol, nil] returned when neither is given.
    # @param warning_source [String] caller name for deprecation warnings.
    def normalize_context_option(context:, register:, default_context:, warning_source:)
      raise_if_conflicting!(context, register)
      return normalize_context_reference(register) || default_context if register
      return default_context unless context_specified?(context)

      normalize_context_reference(context) || default_context
    end

    # Coerce any acceptable context reference (Symbol, String, or
    # `Lutaml::Xml::Namespace`) into a Symbol.
    def normalize_context_reference(reference)
      return nil if reference.nil?
      return reference if reference.is_a?(Symbol)
      return reference.to_sym if reference.is_a?(String)
      return reference.id.to_sym if reference.is_a?(::Lutaml::Xml::Namespace)

      raise ArgumentError, "Unsupported context/register reference: #{reference.inspect}"
    end

    def context_specified?(context)
      !context.equal?(::Dcc::UNSPECIFIED_CONTEXT)
    end

    def raise_if_conflicting!(context, register)
      return unless context_specified?(context) && register

      raise ArgumentError, "Use either `context` or `register`, not both"
    end

    private_class_method :raise_if_conflicting!
  end
end
