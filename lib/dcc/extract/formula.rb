# frozen_string_literal: true

require "rexml/document"

module Dcc
  module Extract
    # `Dcc::Extract::Formula` extracts MathML formula expressions from a
    # parsed DCC and converts them to a Ruby AST that can be evaluated
    # with BigDecimal precision.
    #
    # Only content-MathML is supported (presentation-MathML is opaque text).
    module Formula
      autoload :Ast, "dcc/extract/formula/ast"
      autoload :Parser, "dcc/extract/formula/parser"
      autoload :Evaluator, "dcc/extract/formula/evaluator"
      autoload :Quantity, "dcc/extract/formula/quantity"

      class << self
        # Walk a parsed DCC and return one Ast per `dcc:formula` element
        # that contains a `dcc:mathml` payload.
        #
        # @param dcc [Lutaml::Model::Serializable]
        # @return [Array<Dcc::Extract::Formula::Ast>]
        def call(dcc)
          formulas = []
          walk_for_formulas(dcc, formulas)
          formulas
        end

        private

        def walk_for_formulas(node, accumulator, visited = nil)
          return unless node.is_a?(::Lutaml::Model::Serializable)

          visited ||= ::Set.new
          return if visited.include?(node.object_id)

          visited << node.object_id

          extract_mathml(node, accumulator)
          descend_children(node, accumulator, visited)
        end

        def extract_mathml(node, accumulator)
          return unless node.class.name.end_with?("::Formula")
          return unless node.respond_to?(:mathml)

          mathml = node.mathml
          return unless mathml && !mathml.to_s.empty?

          accumulator << ::Dcc::Extract::Formula::Parser.parse(mathml)
        rescue StandardError
          # Malformed MathML or unsupported construct: skip silently.
        end

        def descend_children(node, accumulator, visited)
          node.class.attributes.each_key do |attr_name|
            value = node.public_send(attr_name)
            Array(value).each do |child|
              walk_for_formulas(child, accumulator, visited) if child.is_a?(::Lutaml::Model::Serializable)
            end
          end
        end
      end
    end
  end
end

require "set"