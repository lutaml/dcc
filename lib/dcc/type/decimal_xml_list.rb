# frozen_string_literal: true

require "bigdecimal"
require "lutaml/model"

module Dcc
  module Type
    # Space-separated list of decimals, as used by D-SI `*XMLList` elements
    # (e.g. `<si:valueXMLList>306 373 448</si:valueXMLList>`). Parses to/from
    # an Array of BigDecimal values.
    class DecimalXmlList < Lutaml::Model::Type::Value
      def self.cast(value)
        return [] if value.nil?
        return value.map { |v| cast_one(v) } if value.is_a?(::Array)

        value.to_s.split(/\s+/).reject(&:empty?).map { |s| cast_one(s) }
      end

      def self.serialize(value)
        return "" if value.nil?

        Array(value).map { |v| serialize_one(v) }.join(" ")
      end

      class << self
        private

        def cast_one(token)
          return token if token.is_a?(::BigDecimal)

          BigDecimal(token.to_s)
        rescue ::ArgumentError => e
          raise Lutaml::Model::Type::InvalidValueError.new(token,
                                                           "invalid decimal in XML list: #{e.message}")
        end

        def serialize_one(value)
          case value
          when ::BigDecimal then value.to_i.to_s == value.to_s("F") ? value.to_i.to_s : value.to_s("F").sub(/\.0\z/, "")
          when ::Float then format("%.15g", value)
          else value.to_s
          end
        end
      end
    end
  end
end
