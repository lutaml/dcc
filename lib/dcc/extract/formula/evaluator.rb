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

        # A cost ceiling, not a correctness one. Three things in here
        # scale with the size of a value, and `BigDecimal#precision`
        # counts digits across the exponent span, so one limit covers
        # all three:
        #
        #   * BigMath reduces a trigonometric argument before it can
        #     answer, and that is linear in the exponent — sin(1e1000)
        #     is 1ms, sin(1e100000) 0.74s, sin(1e1000000) 8.6s.
        #   * exact `**` and `*` allocate one digit at a time, and the
        #     exponent does not constrain that at all: 0.99999999999
        #     raised to 999 twice keeps exponent 0 while going from 11
        #     digits to eleven million.
        #   * the printed value — `to_s("F")` of 1e1000000 is a megabyte.
        #
        # Nothing real comes near it: exp(1000) is 435, tan(pi/2) is 34,
        # 2**1000 is 302, and IEEE double tops out at 1e308.
        #
        # `precision` has been on BigDecimal since 3.0.0, well under the
        # gem's Ruby floor of 3.2.
        MAX_DIGITS = 1_000

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
            ast.bindings.merge(overrides)
              .slice(*ast.variables)
              .to_h { |name, value| [name, sized(name, quantify(value))] }
          end

          # Only the referenced slice is checked. `Formula.bindings_in`
          # builds a Quantity for every identified quantity in the data
          # block before it looks at the formulae, so refusing an
          # oversized one at coercion would take down every other
          # formula in the document over a value none of them uses.
          def sized(name, quantity)
            subject = "Formula variable '#{name}'"
            numbers = quantity.values
            numbers.each { |value| check_size(value, subject) }
            quantity
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
            lists = env.select { |_, quantity| quantity.list? }
            distinct = lists.each_value.map { |q| q.values.size }.uniq
            check_lengths(distinct, lists.keys)

            distinct.first || 1
          end

          # Refuses both ways a referenced list can make a width
          # meaningless. An empty one used to give width zero, so
          # `Array.new(0)` never evaluated the body at all: no values,
          # no error, exit 0 — and a genuinely missing variable went
          # unreported with it, because nothing ever looked one up.
          def check_lengths(distinct, names)
            if distinct.size > 1
              raise ::Dcc::ExtractionError,
                    "Formula variables have mismatched list lengths: " \
                    "#{distinct.sort.inspect}"
            end
            return unless distinct == [0]

            raise ::Dcc::ExtractionError,
                  "Formula variables have empty value lists: " \
                  "#{names.sort.inspect}"
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
            in Ast::Number(value:) then check_size(value, "A formula number")
            in Ast::Constant(name:) then constant(name)
            in (Ast::Variable | Ast::BoundVariable) => ref
              lookup(ref.name, scope)
            in Ast::Apply(operator:, operands:)
              operate(operator, operands.map { |o| evaluate(o, scope) })
            end
          end

          # Needs no size check: BigMath.PI(34) and E(34) are 34 digits
          # by construction, so a constant cannot reach the ceiling.
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
            checked(dispatch(operator, args), operator)
          end

          # Every value the evaluator produces goes through here — the
          # answer of an operation and every intermediate inside an
          # n-ary fold alike. Checking only the answer let
          # 1.25e998 * 1.25e998 * 8e-999 * 8e-999 run the accumulator up
          # to an exponent of 1997 and land back on exactly 1 unnoticed.
          def checked(value, operator, role = "result of")
            check_size(finite(value, operator), "The #{role} #{operator}")
          end

          def check_size(value, subject)
            return value if value.precision <= MAX_DIGITS

            raise ::Dcc::ExtractionError,
                  "#{subject} exceeds the formula limit of " \
                  "#{MAX_DIGITS} digits"
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

          # Folds through `checked` so an intermediate cannot exceed the
          # ceiling on its way to an answer that does not.
          #
          # `Array#sum` seeds with 0 and that seed is observable —
          # `[-0].sum` is 0.0 where `[-0].reduce(:+)` is -0.0 — so `+`
          # folds from the same seed and no printed value moves.
          def fold(operator, args)
            return -args.first if operator == :- && args.size == 1

            operands = operator == :+ ? [BigDecimal(0), *args] : args
            operands.reduce do |left, right|
              checked(step(operator, left, right), operator)
            end
          end

          def step(operator, left, right)
            case operator
            when :+ then left + right
            when :* then left * right
            when :- then left - right
            else divide(left, right)
            end
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

            scaled = checked(exponent * ln(base), :**, "intermediate in")
            BigMath.exp(scaled, PRECISION)
          end

          # `**` chooses its own precision, so a negative exponent is
          # inexact (`3 ** -1` gives 32 digits, not 34). Route it through
          # `divide`.
          def integer_power(base, exponent)
            check_power_size(base, exponent)
            return base**exponent unless exponent.negative?
            raise ::Dcc::ExtractionError, ZERO_DIVISION if base.zero?

            divide(BigDecimal(1), base**-exponent)
          end

          # The exact path allocates the whole number before any result
          # check can see how big it got, so the size is predicted here
          # instead. `2 ** 1e8` takes 2.7s and `2 ** 1e9` 25s, and
          # `(0.99999999999 ** 999) ** 999` needs eleven million digits
          # while its exponent never leaves zero.
          #
          # `precision * |exponent|` is an upper bound, not the exact
          # size, so it refuses some powers that would have fitted:
          # anything with an integer exponent past MAX_DIGITS, however
          # small the base (`2 ** 1001` really lands on 302 digits), and
          # `1 ** huge`, which costs nothing. Predicting exactly means
          # hand-rolling capped exponentiation, and a subtle bug in that
          # loop fails this guard open. An over-refusal is a message; an
          # under-refusal is the CPU-exhaustion path this exists to
          # close. No certificate raises anything to the 1001st power.
          def check_power_size(base, exponent)
            return if base.precision * exponent.abs <= MAX_DIGITS

            raise ::Dcc::ExtractionError,
                  "An exact power in the formula is not provably within " \
                  "the limit of #{MAX_DIGITS} digits"
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

            scaled = checked(divide(ln(value), degree), :root,
                             "intermediate in")
            BigMath.exp(scaled, PRECISION)
          end
        end
      end
    end
  end
end
