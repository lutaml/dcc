# frozen_string_literal: true

require "bigdecimal/math"

module Dcc
  module Extract
    module Formula
      # `Dcc::Extract::Formula::Evaluator` applies a content-MathML head
      # symbol (e.g. `:plus`, `:times`) to a list of evaluated BigDecimal
      # operands. Numeric only — symbolic simplification is out of scope.
      module Evaluator
        # @param head [Symbol] MathML operator name (plus, times, etc.).
        # @param args [Array<Numeric>] evaluated operands.
        # @return [BigDecimal]
        def self.apply(head, args)
          case head
          when :plus   then args.reduce(BigDecimal("0")) { |acc, v| acc + v }
          when :minus  then args.size == 1 ? -args.first : args.first - args.drop(1).reduce(BigDecimal("0")) { |a, v| a + v }
          when :times  then args.reduce(BigDecimal("1")) { |acc, v| acc * v }
          when :divide then divide_chain(args)
          when :power, :pow then args.first ** args.last.to_i
          when :root   then sqrt(args.first)
          when :sqrt   then sqrt(args.first)
          when :exp    then BigDecimal(Math.exp(args.first.to_f).to_s)
          when :ln     then BigDecimal(Math.log(args.first.to_f).to_s)
          when :log    then BigDecimal(Math.log10(args.first.to_f).to_s)
          when :abs    then args.first.abs
          when :sin    then BigDecimal(Math.sin(args.first.to_f).to_s)
          when :cos    then BigDecimal(Math.cos(args.first.to_f).to_s)
          when :tan    then BigDecimal(Math.tan(args.first.to_f).to_s)
          when :max    then args.max
          when :min    then args.min
          when :sum    then args.reduce(BigDecimal("0")) { |a, v| a + v }
          when :product then args.reduce(BigDecimal("1")) { |a, v| a * v }
          else
            raise ::Dcc::ExtractionError,
                  "unsupported MathML operator: #{head.inspect}"
          end
        end

        class << self
          private

          def divide_chain(args)
            args.drop(1).reduce(args.first) { |acc, v| acc / v }
          end

          def sqrt(value)
            # Newton's method for BigDecimal sqrt.
            return BigDecimal("0") if value.zero?

            x = value
            20.times do
              next_x = (x + value / x) / 2
              break if (next_x - x).abs < BigDecimal("1E-30")
              x = next_x
            end
            x
          end
        end
      end
    end
  end
end