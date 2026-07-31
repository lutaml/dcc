# frozen_string_literal: true

require "bigdecimal"
require "lutaml/model"

module Dcc
  # `Dcc::Diff` compares two parsed DCC object trees and returns a
  # `Dcc::Diff::Result` describing structural changes (counts, additions,
  # removals, modifications). Identity is determined by `uniqueIdentifier`
  # for the top-level DCC and by element `@id` / `@refId` for nested items.
  module Diff
    autoload :Result, "dcc/diff/result"
    autoload :Change, "dcc/diff/change"

    # Leaf types compared directly rather than descended into. Numeric covers
    # BigDecimal and Date covers DateTime, so neither needs its own entry.
    PRIMITIVE_TYPES = [
      ::String, ::Numeric, ::Symbol, ::Time, ::Date
    ].freeze

    class << self
      # @param a [Lutaml::Model::Serializable]
      # @param b [Lutaml::Model::Serializable]
      # @return [Dcc::Diff::Result]
      def call(a, b)
        changes = []
        collect_differences(a, b, "", changes)
        Result.new(changes: changes)
      end

      private

      def collect_differences(a, b, path, changes)
        # Both nil - no diff
        return if a.nil? && b.nil?

        # One is nil - add/remove
        if a.nil?
          changes << Change.new(path: path, kind: :add, before: nil,
                                after: summarize(b))
          return
        end
        if b.nil?
          changes << Change.new(path: path, kind: :remove,
                                before: summarize(a), after: nil)
          return
        end

        # Both primitives - compare values
        if primitive?(a) || primitive?(b)
          if a != b
            changes << Change.new(path: path, kind: :change, before: a,
                                  after: b)
          end
          return
        end

        # Both arrays
        if a.is_a?(::Array) || b.is_a?(::Array)
          max = [a.size, b.size].max
          max.times do |i|
            collect_differences(a[i], b[i], "#{path}[#{i}]", changes)
          end
          return
        end

        # Both objects
        keys = (a.class.attributes.keys | b.class.attributes.keys)
        keys.each do |key|
          av = Dcc::TypeGuards.has_attribute?(a, key) ? a.public_send(key) : nil
          bv = Dcc::TypeGuards.has_attribute?(b, key) ? b.public_send(key) : nil
          collect_differences(av, bv, "#{path}/#{key}", changes)
        end
      end

      def primitive?(value)
        return true if value.nil? || [true, false].include?(value)
        return false if value.is_a?(::Array)
        return true if PRIMITIVE_TYPES.any? { |type| value.is_a?(type) }

        # Anything we cannot descend into is compared with `==`, which covers
        # value objects such as decimal XML lists.
        !value.class.respond_to?(:attributes)
      end

      def summarize(node)
        return node.to_s if primitive?(node)

        "#{node.class.name.split('::').last}"
      end
    end
  end
end
