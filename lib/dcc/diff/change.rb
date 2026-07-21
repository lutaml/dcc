# frozen_string_literal: true

module Dcc
  module Diff
    # A single structural change between two DCC object trees.
    Change = ::Struct.new(:path, :kind, :before, :after) do
      def added? = kind == :add
      def removed? = kind == :remove
      def changed? = kind == :change

      def to_s
        case kind
        when :add    then "+ #{path}: #{after}"
        when :remove then "- #{path}: #{before}"
        when :change then "~ #{path}: #{before} -> #{after}"
        else path
        end
      end
    end
  end
end