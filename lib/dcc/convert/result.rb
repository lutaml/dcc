# frozen_string_literal: true

module Dcc
  module Convert
    # Output of a `Dcc::Convert::*` converter. Carries the format and the
    # string payload. Outputs are models per the user's directive:
    # `to_s` returns the rendered payload, `to_json` / `to_yaml` return
    # the formatted payload directly.
    class Result
      attr_reader :format, :payload, :source_class, :schema_version

      # @param format [Symbol, String] the conversion target (`:json`, `:yaml`, etc.).
      # @param payload [String] the rendered output.
      # @param source_class [String, nil] the source model's class name.
      # @param schema_version [String, nil] the DCC schema version.
      def initialize(format:, payload:, source_class: nil, schema_version: nil)
        @format = format.to_sym
        @payload = payload.to_s
        @source_class = source_class
        @schema_version = schema_version
      end

      # `to_s` returns the rendered output.
      def to_s
        @payload
      end

      # Convenience: parse the payload back into Ruby data structures.
      # @return [Object]
      def parsed
        case @format
        when :json
          ::JSON.parse(@payload)
        when :yaml
          ::YAML.safe_load(@payload)
        else
          @payload
        end
      end

      # Already-rendered JSON payload (not a re-render).
      def to_json(*_args)
        @payload
      end

      def to_yaml(*_args)
        @payload
      end
    end
  end
end