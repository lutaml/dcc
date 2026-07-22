# frozen_string_literal: true

module Dcc
  module Extract
    module Formula
      # AST node types for content-MathML. Each carries enough info to be
      # evaluated by `Evaluator`. Immutable value objects.
      module Ast
        # A literal numeric constant.
        Number = ::Struct.new(:value) do
          def evaluate(env) = value
        end

        # A variable reference, looked up in the evaluation environment.
        Variable = ::Struct.new(:name) do
          def evaluate(env)
            env.fetch(name.to_sym) do
              raise ::KeyError, "unbound variable #{name.inspect}"
            end
          end
        end

        # A bound variable (function parameter). Behaves like a Variable
        # at evaluation time but is also reachable via name in lambdas.
        BoundVariable = ::Struct.new(:name) do
          def evaluate(env) = Variable.new(name).evaluate(env)
        end

        # A function application. `head` is the operator name (e.g. :plus,
        # :times); `args` is the list of operand ASTs.
        Apply = ::Struct.new(:head, :args) do
          def evaluate(env)
            vals = args.map { |a| a.evaluate(env) }
            ::Dcc::Extract::Formula::Evaluator.apply(head, vals)
          end
        end

        # A lambda definition with bound variables and a body.
        Lambda = ::Struct.new(:bvars, :body) do
          def evaluate(env)
            # Return a Proc that takes a hash of arg values and evaluates
            # the body in an environment extended with those bindings.
            lambda do |args|
              call_env = env.merge(args)
              body.evaluate(call_env)
            end
          end
        end

        # An identifier with an `xref` attribute (used by PTB to link a
        # variable to a D-SI quantity by refType).
        Identifier = ::Struct.new(:name, :xref) do
          def evaluate(env)
            key = (xref || name).to_sym
            env.fetch(key) { Variable.new(name).evaluate(env) }
          end
        end
      end
    end
  end
end