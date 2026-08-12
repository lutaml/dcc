# frozen_string_literal: true

require "bigdecimal"
require "forwardable"
require "lutaml/model"

module Dcc
  module Type
    # Space-separated list of decimals, as used by D-SI `*XMLList` elements
    # (e.g. `<si:valueXMLList>306 373 448</si:valueXMLList>`). Parses to/from
    # a `Values` list of BigDecimal.
    #
    # `cast` deliberately does not return a plain Array: lutaml-model treats an
    # Array-valued attribute as a collection and would emit one element per
    # decimal instead of a single space-separated list.
    class DecimalXmlList < Lutaml::Model::Type::Value
      # An ordered list of BigDecimals that renders as space-separated text and
      # compares equal to the equivalent Array.
      class Values
        include Enumerable
        extend Forwardable

        def_delegators :@decimals, :size, :length, :empty?, :last, :[]

        def initialize(decimals)
          @decimals = decimals
        end

        def each(&)
          return to_enum(:each) unless block_given?

          @decimals.each(&)
          self
        end

        # Implicit conversion, so `Array#==` delegates back here instead of
        # returning false and making equality asymmetric.
        def to_ary
          @decimals.dup
        end

        # Joined over the serialized decimals, not the raw BigDecimals, so it
        # cannot disagree with `to_s` by emitting "0.72e-1" for "0.072".
        def join(separator = " ")
          map { |decimal| DecimalXmlList.serialize_one(decimal) }.join(separator)
        end

        def to_s
          DecimalXmlList.serialize(self)
        end

        # Dumped as its wire form, so YAML matches JSON rather than leaking a
        # `!ruby/object:` tag that `safe_load` refuses to read back.
        def encode_with(coder)
          coder.represent_scalar(nil, to_s)
        end

        def ==(other)
          case other
          when Values then to_a == other.to_a
          when ::Array then to_a == other
          else false
          end
        end

        # Stricter than `==`, which accepts a plain Array. Hash lookup pairs
        # `eql?` with `hash`, and an Array keyed alongside us would hash the
        # same while comparing equal in only one direction.
        def eql?(other)
          other.is_a?(Values) && to_a == other.to_a
        end

        def hash
          to_a.hash
        end
      end

      def self.cast(value)
        return value if value.is_a?(Values)
        return Values.new([]) if value.nil?

        tokens = value.is_a?(::Array) ? value : value.to_s.split
        Values.new(tokens.map { |token| cast_one(token) })
      end

      def self.serialize(value)
        return "" if value.nil?

        Array(value).map { |v| serialize_one(v) }.join(" ")
      end

      # One decimal in the notation D-SI writes, e.g. 0.072 rather than
      # BigDecimal's own "0.72e-1". `to_s("F")` renders every BigDecimal,
      # finite or not, and `sub` only trims a trailing ".0". That is what
      # lets `NaN` through, which D-SI admits in every decimal type
      # (SI_Format.xsd:1195).
      def self.serialize_one(value)
        reject_infinite!(value)

        case value
        when ::BigDecimal then value.to_s("F").sub(/\.0\z/, "")
        when ::Float then format("%.15g", value)
        else value.to_s
        end
      end

      class << self
        private

        def cast_one(token)
          decimal = token.is_a?(::BigDecimal) ? token : BigDecimal(token.to_s)
          reject_infinite!(decimal)
          decimal
        rescue ::ArgumentError => e
          raise Lutaml::Model::Type::InvalidValueError.new(token,
                                                           "invalid decimal in XML list: #{e.message}")
        end

        # Called from `cast_one` and from the public `serialize_one`, since
        # `serialize` takes a raw BigDecimal and casting is not the only way in.
        def reject_infinite!(value)
          return unless value.is_a?(::BigDecimal) && value.infinite?

          raise Lutaml::Model::Type::InvalidValueError.new(
            value,
            "infinity is not a D-SI decimal: SI_Format.xsd:1195 admits " \
            "numbers and NaN only",
          )
        end
      end
    end
  end
end
