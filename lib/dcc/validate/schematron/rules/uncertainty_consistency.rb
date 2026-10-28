# frozen_string_literal: true

module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that for every `si:realListXMLList` paired with an
        # `si:expandedUncXMLList`, each uncertainty list holds either one
        # entry per value or a single entry broadcast across all of them.
        class UncertaintyConsistency < Base
          UNCERTAINTY_LISTS = {
            uncertainty_xml_list: "uncertaintyXMLList",
            coverage_factor_xml_list: "coverageFactorXMLList",
            coverage_probability_xml_list: "coverageProbabilityXMLList",
            distribution_xml_list: "distributionXMLList",
          }.freeze

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

            if node.class.name.end_with?("::RealListXmlList")
              check_node(node,
                         issues)
            end
            descend(node, issues, visited)
          end

          def check_node(list_node, issues)
            values = list_node.value_xml_list
            unc = list_node.expanded_unc_xml_list
            return unless unc && values

            value_count = entry_count(values)
            UNCERTAINTY_LISTS.each do |attribute, xml_name|
              count = entry_count(unc.public_send(attribute))
              next if consistent?(count, value_count)

              issues << count_mismatch(xml_name, count, value_count)
            end
          end

          def count_mismatch(xml_name, count, value_count)
            issue(
              severity: :error,
              message: "valueXMLList count (#{value_count}) does not " \
                       "match #{xml_name} count (#{count})",
            )
          end

          # Every list here is an xs:list, so its entries are whitespace
          # separated whether the attribute holds a string or a decimal list.
          def entry_count(list)
            list.to_s.split.size
          end

          # A list either carries one entry per value or a single entry that
          # broadcasts across all of them, the way unitXMLList does. Siblings
          # decide independently: PTB ships documents pairing nine
          # uncertainties with one shared coverage factor.
          def consistent?(count, value_count)
            count.zero? || count == 1 || count == value_count
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
