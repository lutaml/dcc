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
            name, model = only(children(math))
            return parse_declaration(model, bindings) if name == "declare"

            Ast.new(name: nil, bound_variables: [],
                    body: node(name, model, []), bindings: bindings)
          end

          private

          def parse_declaration(declaration, bindings)
            nodes = children(declaration)
            check_declaration(nodes)
            lambda_children = children(fetch(nodes, "lambda"))
            bound = bound_variable_names(lambda_children)
            body = expression(without_bvars(lambda_children), bound)
            Ast.new(name: text_of(nodes, "ci"), bound_variables: bound,
                    body: body, bindings: bindings)
          end

          # `fetch` and `text_of` take the first match, so a second
          # <lambda> or a second name <ci> would vanish the same way a
          # second top-level expression used to.
          def check_declaration(nodes)
            names = nodes.map(&:first)
            return if names == %w[ci lambda]

            raise ::Dcc::ExtractionError,
                  "<declare> must hold one <ci> then one <lambda>, " \
                  "found #{names.empty? ? 'nothing' : names.join(', ')}"
          end

          def without_bvars(nodes)
            nodes.reject { |pair| pair.first == "bvar" }
          end

          def bound_variable_names(nodes)
            nodes.select { |pair| pair.first == "bvar" }
              .map { |pair| bound_name(children(pair.last)) }
          end

          # A <bvar> names one variable. MathML also allows a <degree>
          # qualifier there, but that spells a derivative and this
          # evaluator has none to offer, so it is refused rather than
          # ignored — and the message names what was actually there.
          def bound_name(contents)
            names = contents.map(&:first)
            return text(contents.first.last) if names == %w[ci]

            raise ::Dcc::ExtractionError,
                  "<bvar> must contain exactly one <ci>, " \
                  "found #{names.empty? ? 'nothing' : names.join(', ')}"
          end

          # @param nodes [Array<(String, Object)>] ordered
          #   [element name, model] pairs.
          # @return [Object] the single expression node.
          def expression(nodes, bound = [])
            name, model = only(nodes)
            node(name, model, bound)
          end

          # `<math>` and a `<lambda>` body each hold exactly one
          # expression. Taking `.first` of several dropped the rest
          # without a word — the same silent wrong answer this file
          # refuses everywhere else. (`<bvar>` has its own check, in
          # `bound_name`, because a qualifier there is not an
          # expression.)
          def only(nodes)
            case nodes.size
            when 1 then nodes.first
            when 0
              raise ::Dcc::ExtractionError,
                    "dcc:formula contains no formula expression"
            else
              raise ::Dcc::ExtractionError,
                    "dcc:formula contains #{nodes.size} expressions " \
                    "where exactly one is expected"
            end
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
            literal = text(model)
            number = Ast::Number.new(value: literal)
            check_integral(model.type, number.value, literal)
            number
          end

          # `<cn type="integer">1.5</cn>` declares one thing and writes
          # another. Reading it as 1.5 is the same contradiction
          # `base="8"` is refused for.
          #
          # Returns the node explicitly rather than ending on the check:
          # a check's return value in an operand slot would put nil into
          # the tree and leak a raw NoMethodError out of `abs`.
          # Quotes the source lexeme, not `value.to_s("F")`: expanding
          # the decimal turns `1e-100000` — nine bytes of document —
          # into a hundred-kilobyte exception message.
          def check_integral(type, value, literal)
            return unless type == "integer"
            return if value.frac.zero?

            raise ::Dcc::ExtractionError,
                  %(<cn type="integer"> holds a non-integer value: #{literal})
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
