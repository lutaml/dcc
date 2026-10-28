# frozen_string_literal: true

require "bigdecimal"

module Dcc
  module Extract
    # `Dcc::Extract::Formula` pulls content-MathML formulae out of a parsed
    # DCC. Each `dcc:formula` that carries a `dcc:mathml` becomes one `Ast`,
    # bound to the `dcc:quantity` values sitting in the same `dcc:data`
    # block — that is where PTB puts a formula's parameters and inputs.
    module Formula
      autoload :Ast, "dcc/extract/formula/ast"
      autoload :Evaluator, "dcc/extract/formula/evaluator"
      autoload :Parser, "dcc/extract/formula/parser"
      autoload :Quantity, "dcc/extract/formula/quantity"

      class << self
        # @param dcc [Lutaml::Model::Serializable] a parsed DCC.
        # @return [Array<Dcc::Extract::Formula::Ast>] in document order.
        def call(dcc)
          data_blocks(dcc).flat_map { |data| formulae_in(data) }
        end

        private

        def formulae_in(data)
          bindings = bindings_in(data)
          data.formula.filter_map do |formula|
            math = formula.mathml&.math
            Parser.call(math, bindings: bindings) if math
          end
        end

        # Parameters live in `dcc:data/dcc:list/dcc:quantity`, but the XSD
        # also allows a bare `dcc:quantity` directly under `dcc:data`.
        def bindings_in(data)
          quantities_in(data).each_with_object({}) do |quantity, bindings|
            next unless quantity.id

            value = quantity_value(quantity)
            bindings[quantity.id] = value if value
          end
        end

        # `dcc:listType` is recursive, and both it and `dcc:dataType`
        # expose `quantity` and `list`. Walking only the first level of
        # lists loses every binding nested below it.
        def quantities_in(container)
          container.quantity +
            container.list.flat_map { |list| quantities_in(list) }
        end

        # `si:value` is declared `attribute :value, :string` in
        # `lib/dcc/si/base/real.rb` — completely unvalidated, so a real
        # document can carry "banana", "Infinity", or nothing at all. Hand
        # it to Quantity untouched and let the one coercion boundary decide;
        # calling `BigDecimal` here would leak a raw ArgumentError out of a
        # public extraction call.
        #
        # Both `real` and `real_list_xml_list` are collection attributes on
        # `Dcc::V3::Quantity`, so both need `.first`.
        def quantity_value(quantity)
          real = quantity.real.first
          return scalar(real) if real

          list = quantity.real_list_xml_list.first
          list_values(list) if list
        end

        def scalar(real)
          Quantity.new(value: real.value, unit: real.unit, uncertainty: nil)
        end

        def list_values(list)
          Quantity.new(
            value: list.value_xml_list,
            unit: list.unit_xml_list,
            uncertainty: nil,
          )
        end

        # Same shape as `Dcc::Extract::File.each`: walk the model graph and
        # collect every `dcc:data` node in document order.
        def data_blocks(dcc)
          blocks = []
          walk(dcc, ::Set.new, blocks)
          blocks
        end

        # `Set#add?` returns nil when already present, so it doubles as the
        # cycle guard for the self-referential list types.
        def walk(node, visited, blocks)
          return unless node.is_a?(::Lutaml::Model::Serializable)
          return unless visited.add?(node.object_id)

          blocks << node if data?(node)
          node.class.attributes.each_key do |attr_name|
            Array(node.public_send(attr_name)).each do |child|
              walk(child, visited, blocks)
            end
          end
        end

        def data?(node)
          node.class.name.end_with?("::Data")
        end
      end
    end
  end
end
