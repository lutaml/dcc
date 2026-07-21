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
          changes << Change.new(path: path, kind: :add, before: nil, after: summarize(b))
          return
        end
        if b.nil?
          changes << Change.new(path: path, kind: :remove, before: summarize(a), after: nil)
          return
        end

        # Both primitives - compare values
        if primitive?(a) || primitive?(b)
          if a != b
            changes << Change.new(path: path, kind: :change, before: a, after: b)
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
          av = a.respond_to?(key) ? a.public_send(key) : nil
          bv = b.respond_to?(key) ? b.public_send(key) : nil
          collect_differences(av, bv, "#{path}/#{key}", changes)
        end
      end

      def primitive?(value)
        return true if value.nil?
        return true if value.is_a?(::String) || value.is_a?(::Numeric) || value.is_a?(::Symbol)
        return true if value == true || value == false
        return true if value.is_a?(::Time) || value.is_a?(::Date) || value.is_a?(::DateTime)
        return true if value.is_a?(::BigDecimal)

        false
      end

      def summarize(node)
        return node.to_s if primitive?(node)

        "#{node.class.name.split('::').last}"
      end
    end
  end
end