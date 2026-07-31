# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module Extract
    module Formula
      # One extracted formula: its declared name, the lambda's bound
      # variables, the expression tree, and the variable bindings found
      # alongside it in the DCC.
      class Ast
        attr_reader :name, :bound_variables, :body, :bindings

        # @param name [String, nil] the `ml:declare` function name (e.g. "R").
        # @param bound_variables [Array<String>] the `ml:lambda` bvar names.
        # @param body [Object] the expression tree root.
        # @param bindings [Hash{String => Quantity}] variable values
        #   found in the DCC.
        def initialize(name:, bound_variables:, body:, bindings:)
          @name = name
          @bound_variables = bound_variables
          @body = body
          @bindings = bindings
        end

        # @param overrides [Hash{String => BigDecimal, Array<BigDecimal>}]
        # @return [Array<BigDecimal>]
        def evaluate(overrides = {})
          Evaluator.call(self, overrides)
        end

        def to_s
          "#{name || '(anonymous)'}(#{bound_variables.join(', ')})"
        end

        # `Formula.call` hands `Ast` objects back as public API, so callers
        # legitimately build and hold nodes. Number therefore coerces
        # through the same boundary as Quantity.
        Number = ::Data.define(:value) do
          def initialize(value:)
            super(value: Quantity.decimal(value))
          end
        end

        Variable = ::Data.define(:name)
        BoundVariable = ::Data.define(:name)

        # The symbols the evaluator can dispatch on. Its `case` statements
        # have no `else`, so an unrecognised name would evaluate to nil —
        # a silent wrong answer for a constant, a NoMethodError for an
        # operator. Rejecting at construction keeps both out of the API.
        CONSTANTS = %i[pi e].freeze
        OPERATORS = %i[+ - * / ** root exp ln log sin cos tan abs].freeze

        Constant = ::Data.define(:name) do
          def initialize(name:)
            Constant.check_name(name)
            super
          end

          def self.check_name(name)
            return if CONSTANTS.include?(name)

            raise ::Dcc::ExtractionError,
                  "#{name} is not a formula constant, expected one of " \
                  "#{CONSTANTS.join(', ')}"
          end
        end

        # How many operands each operator accepts; anything absent is a
        # single-argument function. Without this, `<power/>` with one
        # operand quietly computes `x ** x` and with three quietly drops
        # the middle one — wrong answers rather than errors.
        ARITY = {
          "+": (1..),
          "*": (1..),
          "-": (1..2),
          "/": (2..2),
          "**": (2..2),
          root: (1..2),
        }.freeze

        UNARY = (1..1)

        # Checked in the constructor so a directly-built AST is held to the
        # same contract as a parsed one.
        Apply = ::Data.define(:operator, :operands) do
          def initialize(operator:, operands:)
            Apply.check_operator(operator)
            Apply.check_arity(operator, operands)
            super(operator: operator, operands: operands.dup.freeze)
          end

          def self.check_operator(operator)
            return if OPERATORS.include?(operator)

            raise ::Dcc::ExtractionError,
                  "#{operator} is not a formula operator, expected one of " \
                  "#{OPERATORS.join(', ')}"
          end

          def self.check_arity(operator, operands)
            allowed = ARITY.fetch(operator, UNARY)
            return if allowed.cover?(operands.size)

            expected = allowed.end ? allowed.to_s : "#{allowed.begin} or more"
            raise ::Dcc::ExtractionError,
                  "#{operator} takes #{expected} operand(s) in formula, " \
                  "got #{operands.size}"
          end
        end
      end
    end
  end
end
