# frozen_string_literal: true

require "base64"
require "lutaml/model"

module Dcc
  module Type
    # Base64-encoded binary data, used by `dcc:dataBase64` in
    # `dcc:byteDataType`.
    #
    # The wire format is base64 text (`VGVzdAo=`). We pass it through
    # unchanged on `cast` so that round-trip serialization is byte-identical.
    # Callers that need the decoded binary bytes call `.decode`.
    class Base64Binary < Lutaml::Model::Type::Value
      def self.cast(value)
        return nil if value.nil? || value == ""
        unless value.is_a?(::String)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "expected binary String")
        end

        value
      end

      def self.serialize(value)
        return nil if value.nil?

        unless value.is_a?(::String)
          raise Lutaml::Model::Type::InvalidValueError.new(value, "expected binary String")
        end

        value
      end

      # Convenience: decode the base64 string to binary bytes.
      # @param value [String, nil]
      # @return [String] binary ASCII-8BIT string, or `""` if invalid.
      def self.decode(value)
        return "" unless value && !value.to_s.empty?

        ::Base64.strict_decode64(value.to_s).b
      rescue ::ArgumentError
        ""
      end

      # Convenience: encode binary bytes to base64 text.
      # @param value [String, nil]
      # @return [String, nil]
      def self.encode(value)
        return nil if value.nil?

        ::Base64.strict_encode64(value)
      end
    end
  end
end