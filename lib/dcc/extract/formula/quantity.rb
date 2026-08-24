# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module Extract
    module Formula
      # A named numeric binding taken from a `dcc:quantity`. `value` is a
      # single `BigDecimal` for `si:real` and an array for the `si:*XMLList`
      # forms. `uncertainty` is part of the shape callers see, but nothing
      # populates it yet — extraction always passes nil.
      #
      # `Quantity.decimal` is the one place untrusted input becomes a
      # BigDecimal. The constructor runs every value through it, so a
      # Quantity cannot exist holding a non-finite or non-numeric value.
      # That invariant is what lets `Evaluator#quantify` trust its contents.
      Quantity = ::Data.define(:value, :unit, :uncertainty) do
        # The single coercion boundary for the whole formula pipeline: the
        # parser's `<cn>` text, the extractor's `si:value` (declared merely
        # `:string`, so it can hold anything), and the evaluator's overrides
        # all land here.
        #
        # @param input [Object] anything that might be a number.
        # @return [BigDecimal] finite, always.
        # @raise [Dcc::ExtractionError] if it is not a finite number.
        def self.decimal(input)
          number = input.is_a?(::BigDecimal) ? input : from_text(input)
          unless number.finite?
            raise ::Dcc::ExtractionError,
                  "Formula value is not a finite number: #{input.inspect}"
          end

          number
        rescue ArgumentError
          raise ::Dcc::ExtractionError,
                "Formula value is not a number: #{input.inspect}"
        end

        # `BigDecimal("1_000")` quietly reads 1000, but no document writes a
        # number that way. Malformed text, not a value ten times its face.
        def self.from_text(input)
          text = input.to_s
          raise ::ArgumentError if text.include?("_")

          BigDecimal(text)
        end
        private_class_method :from_text

        # Lists are narrowed with `Array.try_convert`, not `is_a?(Array)`:
        # the D-SI branch hands back a `Dcc::Type::DecimalXmlList::Values`,
        # which is array-like but is not an Array. `try_convert` also
        # rejects an object whose `to_ary` breaks the protocol, which a
        # bare `respond_to?(:to_ary)` would pass through to a NoMethodError.
        #
        # `Data` freezes the struct but not what it holds, so the coerced
        # list is frozen too.
        def initialize(value:, unit: nil, uncertainty: nil)
          super(value: Quantity.coerce(value), unit: unit,
                uncertainty: uncertainty)
        end

        def self.coerce(value)
          return decimal(value) unless value.respond_to?(:to_ary)

          list = ::Array.try_convert(value)
          raise ::Dcc::ExtractionError, broken_list(value) if list.nil?

          list.map { |item| decimal(item) }.freeze
        rescue ::TypeError
          raise ::Dcc::ExtractionError, broken_list(value)
        end

        def self.broken_list(value)
          "Formula value is not a usable list: #{value.class}"
        end

        # @return [Array<BigDecimal>]
        def values
          list? ? value : [value]
        end

        # @return [Boolean]
        def list?
          value.is_a?(::Array)
        end
      end
    end
  end
end
