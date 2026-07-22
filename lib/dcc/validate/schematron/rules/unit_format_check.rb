# frozen_string_literal: true

module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that SI unit expressions contain no whitespace and
        # that `unitXMLList` element count matches `valueXMLList` count.
        class UnitFormatCheck < Base
          def check_on(dcc)
            issues = []
            return issues unless dcc.is_a?(::Lutaml::Model::Serializable)

            walk(dcc, issues, ::Set.new)
            issues
          end

          private

          def walk(node, issues, visited)
            return unless node.is_a?(::Lutaml::Model::Serializable)
            return if visited.include?(node.object_id)

            visited << node.object_id

            check_single_unit(node, issues)
            check_list_unit(node, issues)
            descend(node, issues, visited)
          end

          def check_single_unit(node, issues)
            return unless node.class.name.end_with?("::Real", "::Complex", "::Constant")
            return unless node.respond_to?(:unit)

            unit = node.unit
            return unless unit && unit.to_s.match?(/\s/)

            issues << issue(
              severity: :error,
              message: "si:unit '#{unit}' must not contain whitespace",
            )
          end

          def check_list_unit(node, issues)
            return unless node.class.name.end_with?("::RealListXmlList")
            return unless node.respond_to?(:unit_xml_list)

            unit_list = node.unit_xml_list
            value_list = node.respond_to?(:value_xml_list) ? node.value_xml_list : nil
            return unless unit_list && value_list

            unit_count = unit_list.to_s.split(/\s+/).length
            value_count = Array(value_list).length
            return if unit_count == value_count || unit_count == 1

            issues << issue(
              severity: :error,
              message: "unitXMLList count (#{unit_count}) does not match valueXMLList count (#{value_count})",
            )
          end

          def descend(node, issues, visited)
            node.class.attributes.each_key do |attr_name|
              value = node.public_send(attr_name)
              Array(value).each { |child| walk(child, issues, visited) }
            end
          end
        end
      end
    end
  end
end

require "set"