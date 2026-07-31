# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/math"

module Dcc
  module Extract
    module Formula
      # Evaluates a `Formula::Ast` numerically.
      #
      # Only variables the formula actually references take part:
      # extraction hands over every identified quantity in the data block,
      # and letting an unreferenced sibling list drive the result width
      # would fail valid formulae. Referenced list variables must agree on
      # length and combine element-wise, so the result is always an array.
      #
      # PRECISION applies to inexact operations only — `/`, `root`, `exp`,
      # `ln`, `log`, the trig functions, non-integer `**` and negative
      # integer `**`. Addition, subtraction, multiplication and
      # non-negative integer powers stay exact.
      #
      # Only the long-stable `BigMath` subset is used (`sqrt`, `exp`,
      # `log`, `sin`, `cos`, `PI`, `E`) — `BigMath.tan` and
      # `BigMath.log10` are recent additions and `bigdecimal` ships as a
      # bundled gem from Ruby 3.4, so the version we get is not ours to
      # assume.
      module Evaluator
        PRECISION = 34
        TEN = BigDecimal(10)
        ZERO_DIVISION = "Division by zero in formula"

        class << self
          # @param ast [Dcc::Extract::Formula::Ast]
          # @param overrides [Hash{String => Object}]
          # @return [Array<BigDecimal>]
          def call(ast, overrides = {})
            env = environment(ast, overrides)
            Array.new(width(env)) do |index|
              evaluate(ast.body, scope(env, index))
            end
          end

          private

          # Values stay wrapped in a Quantity through the whole environment
          # so `list?` survives. Flattening to a bare array here would make
          # a genuine one-element list indistinguishable from a scalar, and
          # it would then broadcast against a longer list instead of
          # raising a length mismatch.
          def environment(ast, overrides)
            referenced = referenced_names(ast.body)
            ast.bindings.merge(overrides)
              .slice(*referenced)
              .transform_values { |value| quantify(value) }
          end

          # @return [Array<String>] every variable the expression mentions.
          def referenced_names(node)
            case node
            in (Ast::Variable | Ast::BoundVariable) => ref then [ref.name]
            in Ast::Apply(operands:) then operands.flat_map { |o| referenced_names(o) }
            else []
            end
          end

          # A Quantity coerced every value in its constructor, so its
          # contents are already finite BigDecimals. A raw override has had
          # no such treatment, so it goes through the same constructor.
          def quantify(value)
            return value if value.is_a?(Quantity)

            Quantity.new(value: value)
          end

          # Only list variables set the width; scalars broadcast. Every
          # list must agree, whatever its length — a one-element list is
          # still a list.
          def width(env)
            lengths = env.each_value.select(&:list?).map { |q| q.values.size }
            distinct = lengths.uniq
            if distinct.size > 1
              raise ::Dcc::ExtractionError,
                    "Formula variables have mismatched list lengths: " \
                    "#{distinct.sort.inspect}"
            end

            distinct.first || 1
          end

          def scope(env, index)
            env.transform_values do |quantity|
              quantity.list? ? quantity.values[index] : quantity.value
            end
          end

          # Bound and free variables resolve identically; the distinction
          # matters to the parser, not here. They share one clause via
          # `(A | B) => ref`, which binds the node itself — `A(name:) |
          # B(name:)` is a syntax error ("duplicated variable name").
          def evaluate(node, scope)
            case node
            in Ast::Number(value:) then value
            in Ast::Constant(name:) then constant(name)
            in (Ast::Variable | Ast::BoundVariable) => ref
              lookup(ref.name, scope)
            in Ast::Apply(operator:, operands:)
              operate(operator, operands.map { |o| evaluate(o, scope) })
            end
          end

          def constant(name)
            case name
            when :pi then BigMath.PI(PRECISION)
            when :e then BigMath.E(PRECISION)
            end
          end

          def lookup(name, scope)
            scope.fetch(name) do
              raise ::Dcc::ExtractionError,
                    "No value for formula variable '#{name}'"
            end
          end

          # Every computed value is checked before it can become another
          # operand. Guarding inputs alone is not enough: `exp(1e100)` is
          # Infinity and `sin(Infinity)` is NaN from finite inputs, and a
          # non-finite operand then poisons everything above it. A huge but
          # finite result still passes.
          def operate(operator, args)
            finite(dispatch(operator, args), operator)
          end

          def finite(result, operator)
            return result if result.finite?

            raise ::Dcc::ExtractionError,
                  "#{operator} produced a non-finite result in formula"
          end

          # Split by shape: n-ary algebraic operators fold over their
          # operands, the rest are single-argument functions.
          def dispatch(operator, args)
            case operator
            when :+, :*, :-, :/ then fold(operator, args)
            when :** then power(args.first, args.last)
            when :root then root(args.first, args[1])
            else function(operator, args.first)
            end
          end

          def fold(operator, args)
            case operator
            when :+ then args.sum
            when :* then args.reduce(:*)
            when :- then negate_or_subtract(args)
            else args.reduce { |a, b| divide(a, b) }
            end
          end

          def negate_or_subtract(args)
            args.size == 1 ? -args.first : args.reduce(:-)
          end

          def function(operator, arg)
            case operator
            when :exp then BigMath.exp(arg, PRECISION)
            when :ln then ln(arg)
            when :log then divide(ln(arg), ln(TEN))
            when :abs then arg.abs
            else trigonometric(operator, arg)
            end
          end

          def trigonometric(operator, arg)
            case operator
            when :sin then BigMath.sin(arg, PRECISION)
            when :cos then BigMath.cos(arg, PRECISION)
            when :tan then tan(arg)
            end
          end

          # BigDecimal returns Infinity/NaN for a zero divisor rather than
          # raising, so guard the input.
          def divide(numerator, denominator)
            raise ::Dcc::ExtractionError, ZERO_DIVISION if denominator.zero?

            numerator.div(denominator, PRECISION)
          end

          def tan(value)
            divide(BigMath.sin(value, PRECISION),
                   BigMath.cos(value, PRECISION))
          end

          def ln(value)
            if value <= 0
              raise ::Dcc::ExtractionError,
                    "Logarithm of a non-positive value in formula"
            end

            BigMath.log(value, PRECISION)
          end

          # Non-negative integer exponents stay exact; everything else goes
          # through the explicit-precision path. `0 ** 0.5` is 0, not an
          # error, so zero is handled before the ln guard can reject it.
          def power(base, exponent)
            return integer_power(base, exponent.to_i) if exponent.frac.zero?
            return zero_to_the(exponent) if base.zero?
            if base.negative?
              raise ::Dcc::ExtractionError,
                    "Cannot raise a negative base to a fractional power " \
                    "in formula"
            end

            BigMath.exp(exponent * ln(base), PRECISION)
          end

          # `**` chooses its own precision, so a negative exponent is
          # inexact (`3 ** -1` gives 32 digits, not 34). Route it through
          # `divide`.
          def integer_power(base, exponent)
            return base**exponent unless exponent.negative?
            raise ::Dcc::ExtractionError, ZERO_DIVISION if base.zero?

            divide(BigDecimal(1), base**-exponent)
          end

          def zero_to_the(exponent)
            raise ::Dcc::ExtractionError, ZERO_DIVISION if exponent.negative?

            BigDecimal(0)
          end

          # Content MathML spells roots as `<root/>` with an optional
          # `<degree>`; mml exposes no content `sqrt` element. Odd-degree
          # roots of negative values are out of scope — the exp/ln path
          # cannot produce them. A zero radicand is legitimate and is
          # answered before the ln guard sees it.
          def root(value, degree)
            if value.negative?
              raise ::Dcc::ExtractionError,
                    "Cannot take the root of a negative value in formula"
            end
            return BigMath.sqrt(value, PRECISION) if degree.nil? || degree == 2

            nth_root(value, degree)
          end

          def nth_root(value, degree)
            if degree.zero?
              raise ::Dcc::ExtractionError, "Root of degree zero in formula"
            end
            return zero_to_the(degree) if value.zero?

            BigMath.exp(divide(ln(value), degree), PRECISION)
          end
        end
      end
    end
  end
end
