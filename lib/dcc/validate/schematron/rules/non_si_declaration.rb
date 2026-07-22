# frozen_string_literal: true

module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates that non-SI units (prefixed with `|`) are declared
        # somewhere in the DCC via `dcc:nonSIUnit` and `dcc:nonSIDefinition`
        # elements inside `dcc:statement`.
        class NonSiDeclaration < Base
          def check_on(dcc)
            issues = []
            return issues unless dcc.is_a?(::Lutaml::Model::Serializable)

            declared_units = collect_declared_non_si_units(dcc, ::Set.new)
            used_units = ::Set.new
            walk_for_used_units(dcc, used_units, ::Set.new)

            (used_units - declared_units).each do |unit|
              issues << issue(
                severity: :error,
                message: "non-SI unit '#{unit}' is used but not declared in dcc:nonSIUnit",
              )
            end
            issues
          end

          private

          def collect_declared_non_si_units(node, visited)
            return [].to_set unless node.is_a?(::Lutaml::Model::Serializable)
            return [].to_set if visited.include?(node.object_id)

            visited << node.object_id
            declared = collect_from_node(node)
            node.class.attributes.each_key do |attr_name|
              value = node.public_send(attr_name)
              Array(value).each do |child|
                declared += collect_declared_non_si_units(child, visited) if child.is_a?(::Lutaml::Model::Serializable)
              end
            end
            declared
          end

          def collect_from_node(node)
            return [].to_set unless node.respond_to?(:non_si_unit)

            u = node.non_si_unit
            u.to_s.empty? ? [].to_set : ::Set.new([u.to_s])
          end

          def walk_for_used_units(node, accumulator, visited)
            return unless node.is_a?(::Lutaml::Model::Serializable)
            return if visited.include?(node.object_id)

            visited << node.object_id
            extract_non_si_unit(node, accumulator)
            node.class.attributes.each_key do |attr_name|
              value = node.public_send(attr_name)
              Array(value).each { |child| walk_for_used_units(child, accumulator, visited) }
            end
          end

          def extract_non_si_unit(node, accumulator)
            %i[unit unit_xml_list].each do |attr|
              next unless Dcc::TypeGuards.has_attribute?(node, attr)

              v = node.public_send(attr)
              next if v.nil? || v.to_s.empty?

              v.to_s.split(/\s+/).each do |tok|
                accumulator << tok if tok.start_with?("|")
              end
            end
          end
        end
      end
    end
  end
end

require "set"