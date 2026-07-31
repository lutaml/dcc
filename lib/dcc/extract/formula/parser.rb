# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module Extract
    module Formula
      # Turns an `Mml::V3::Math` model into a `Formula::Ast`.
      #
      # mml splits an element's children into one collection per child type
      # (`apply_value`, `ci_value`, …), which loses order across types.
      # `element_order` records the original child sequence, so we walk that
      # and pop from the matching collection with a per-name cursor.
      module Parser
        OPERATORS = {
          "plus" => :+,
          "minus" => :-,
          "times" => :*,
          "divide" => :/,
          "power" => :**,
          "root" => :root,
          "exp" => :exp,
          "ln" => :ln,
          "log" => :log,
          "sin" => :sin,
          "cos" => :cos,
          "tan" => :tan,
          "abs" => :abs,
        }.freeze

        CONSTANTS = { "pi" => :pi, "exponentiale" => :e }.freeze

        # `<cn>` encodings whose value is a single decimal literal. Every
        # other type spreads the number across `<sep/>`-separated parts.
        PLAIN_CN_TYPES = %w[real integer double].freeze

        class << self
          # @param math [Mml::V3::Math]
          # @param bindings [Hash{String => Quantity}]
          # @return [Dcc::Extract::Formula::Ast]
          def call(math, bindings: {})
            declaration = math.declare_value.first
            return parse_declaration(declaration, bindings) if declaration

            body = expression(children(math))
            Ast.new(name: nil, bound_variables: [], body: body,
                    bindings: bindings)
          end

          private

          def parse_declaration(declaration, bindings)
            nodes = children(declaration)
            lambda_children = children(fetch(nodes, "lambda"))
            bound = bound_variable_names(lambda_children)
            body = expression(without_bvars(lambda_children), bound)
            Ast.new(name: text_of(nodes, "ci"), bound_variables: bound,
                    body: body, bindings: bindings)
          end

          def without_bvars(nodes)
            nodes.reject { |pair| pair.first == "bvar" }
          end

          def bound_variable_names(nodes)
            nodes.select { |pair| pair.first == "bvar" }
              .map { |pair| text_of(children(pair.last), "ci") }
          end

          # @param nodes [Array<(String, Object)>] ordered
          #   [element name, model] pairs.
          # @return [Object] the single expression node.
          def expression(nodes, bound = [])
            name, model = nodes.first
            if name.nil?
              raise ::Dcc::ExtractionError,
                    "dcc:formula contains no formula expression"
            end

            node(name, model, bound)
          end

          def node(name, model, bound)
            case name
            when "apply" then apply(model, bound)
            when "cn" then number_node(model)
            when "ci" then variable(text(model), bound)
            else constant_node(name)
            end
          end

          # A structured `<cn>` splits its number across text segments
          # separated by `<sep/>`, and `text` concatenates them, so a
          # rational `1<sep/>2` would silently read as 12 rather than one
          # half. A wrong answer is worse than a refusal, so encodings we
          # do not implement are rejected outright.
          #
          # No explicit coercion here — Ast::Number's constructor runs the
          # text through Quantity.decimal.
          def number_node(model)
            check_plain_number(model)
            Ast::Number.new(value: text(model))
          end

          def check_plain_number(model)
            check_base(model)
            unless model.sep_value.empty?
              raise ::Dcc::ExtractionError,
                    "Structured <cn> with <sep/> is not supported"
            end
            return if model.type.nil? || PLAIN_CN_TYPES.include?(model.type)

            raise ::Dcc::ExtractionError,
                  "Unsupported <cn> type: #{model.type}"
          end

          # `<cn base="8">17</cn>` is octal — fifteen, not seventeen.
          # Reading any other base as decimal is the same silent wrong
          # number the `<sep/>` check refuses, so only base 10 is accepted.
          def check_base(model)
            return if model.base.nil? || model.base == "10"

            raise ::Dcc::ExtractionError,
                  "Unsupported <cn> base: #{model.base}"
          end

          def constant_node(name)
            constant = CONSTANTS.fetch(name) do
              raise ::Dcc::ExtractionError,
                    "Unsupported MathML element: #{name}"
            end
            Ast::Constant.new(name: constant)
          end

          def apply(model, bound)
            (operator_name,), *operands = children(model)
            operator = OPERATORS.fetch(operator_name) do
              raise ::Dcc::ExtractionError,
                    "Unsupported MathML operator: #{operator_name}"
            end
            Ast::Apply.new(
              operator: operator,
              operands: operand_nodes(operator, operands, bound),
            )
          end

          def operand_nodes(operator, operands, bound)
            return root_operands(operands, bound) if operator == :root

            operands.map { |name, child| node(name, child, bound) }
          end

          # MathML puts an optional `<degree>` wrapper before the radicand.
          # Unwrap it and store operands as [value, degree]. Cardinality is
          # enforced here: silently taking `.first` of several radicands or
          # several degrees would corrupt the evaluator's operand ordering.
          def root_operands(operands, bound)
            degrees, values =
              operands.partition { |pair| pair.first == "degree" }
            check_root_arity(values, degrees)

            name, child = values.first
            nodes = [node(name, child, bound)]
            return nodes if degrees.empty?

            nodes + [degree_node(degrees.first.last, bound)]
          end

          def check_root_arity(values, degrees)
            unless values.size == 1
              raise ::Dcc::ExtractionError,
                    "<root> must have exactly one radicand, " \
                    "found #{values.size}"
            end
            return unless degrees.size > 1

            raise ::Dcc::ExtractionError,
                  "<root> must have at most one <degree>, " \
                  "found #{degrees.size}"
          end

          def degree_node(model, bound)
            contents = children(model)
            unless contents.size == 1
              raise ::Dcc::ExtractionError,
                    "<degree> must contain exactly one expression, " \
                    "found #{contents.size}"
            end

            name, child = contents.first
            node(name, child, bound)
          end

          def variable(name, bound)
            return Ast::BoundVariable.new(name: name) if bound.include?(name)

            Ast::Variable.new(name: name)
          end

          # Rebuild the original child sequence from `element_order`.
          # @return [Array<(String, Object)>]
          def children(model)
            cursors = ::Hash.new(0)
            elements = model.element_order.select do |e|
              e.node_type == :element
            end
            elements.map do |element|
              name = element.name
              child = collection(model, name)[cursors[name]]
              cursors[name] += 1
              [name, child]
            end
          end

          # `element_order` can name any MathML element; only the ones mml
          # models have a `*_value` reader. This is a boundary check against
          # the gem, not defensive padding.
          def collection(model, name)
            reader = :"#{name.tr('-', '_')}_value"
            unless model.respond_to?(reader)
              raise ::Dcc::ExtractionError,
                    "Unsupported MathML element: #{name}"
            end

            model.public_send(reader)
          end

          def fetch(nodes, name)
            nodes.assoc(name)&.last ||
              raise(::Dcc::ExtractionError,
                    "Expected a <#{name}> element in dcc:formula")
          end

          def text_of(nodes, name)
            text(fetch(nodes, name))
          end

          def text(model)
            Array(model.value).join.strip
          end
        end
      end
    end
  end
end
