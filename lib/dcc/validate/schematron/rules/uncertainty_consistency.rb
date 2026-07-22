# frozen_string_literal: true

module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that for every `si:realListXMLList` paired with an
        # `si:expandedUncXMLList`, the count of values matches the count
        # of uncertainty entries.
        class UncertaintyConsistency < Base
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

            check_node(node, issues) if node.class.name.end_with?("::RealListXmlList")
            descend(node, issues, visited)
          end

          def check_node(list_node, issues)
            values = list_node.value_xml_list
            unc = list_node.expanded_unc_xml_list
            return unless unc && values

            unc_count = Array(unc.uncertainty_xml_list).size
            value_count = Array(values).size
            return if unc_count == value_count || unc_count.zero?

            issues << issue(
              severity: :error,
              message: "valueXMLList count (#{value_count}) does not match expandedUncertaintyXMLList count (#{unc_count})",
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