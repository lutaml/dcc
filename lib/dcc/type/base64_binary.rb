# frozen_string_literal: true

require "base64"
require "lutaml/model"

module Dcc
  module Type
    # Base64-encoded binary data, used by `dcc:dataBase64` in `dcc:byteDataType`.
    # Round-trips between a binary String and its base64 textual form.
    #
    # On the wire: `VGVzdAo=` (text)
    # In Ruby: `"Test\n"` (binary ASCII-8BIT string)
    class Base64Binary < Lutaml::Model::Type::Value
      def self.cast(value)
        return nil if value.nil? || value == ""
        return value if value.is_a?(::String) && value.encoding == ::Encoding::BINARY

        decoded = ::Base64.strict_decode64(value.to_s)
        decoded.force_encoding(::Encoding::BINARY)
      rescue ::ArgumentError => e
        raise Lutaml::Model::Type::InvalidValueError,
              "invalid base64 data: #{e.message}"
      end

      def self.serialize(value)
        return nil if value.nil?

        unless value.is_a?(::String)
          raise Lutaml::Model::Type::InvalidValueError,
                "expected binary String, got #{value.class}"
        end

        ::Base64.strict_encode64(value.force_encoding(::Encoding::BINARY))
      end
    end
  end
end
