# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # `dcc:usedMethods` must appear somewhere (global, list, or quantity
        # level). Error if missing everywhere.
        class UsedMethodsPlacement < Base
          def check_on(dcc)
            issues = []
            return issues unless Dcc::TypeGuards.has_attribute?(dcc, :measurement_results)

            mr_list = safe_attr(dcc.measurement_results, :measurement_result)
            return issues if mr_list.empty?

            any_used = mr_list.any? do |mr|
              Dcc::TypeGuards.has_attribute?(mr, :used_methods) && !mr.used_methods.nil? ||
                mr_has_descendant?(mr, :used_methods)
            end

            issues << issue(
              severity: :error,
              message: "dcc:usedMethods is missing in every measurementResult and its descendants",
            ) unless any_used

            issues
          end

          private

          def mr_has_descendant?(mr, attr_name)
            return false unless Dcc::TypeGuards.has_attribute?(mr, :results) && mr.results

            result = safe_attr(mr.results, :result)
            result.any? { |r| descendant_has?(r, attr_name) }
          end

          def descendant_has?(node, attr_name)
            return false unless node.is_a?(::Lutaml::Model::Serializable)

            if Dcc::TypeGuards.has_attribute?(node, attr_name) && !node.public_send(attr_name).nil?
              return true
            end

            node.class.attributes.each_key do |attr|
              value = node.public_send(attr)
              next unless value.is_a?(::Array) || value.is_a?(::Lutaml::Model::Serializable)

              Array(value).any? { |child| descendant_has?(child, attr_name) }
            end
            false
          end

          def safe_attr(parent, attr)
            return [] unless parent && parent.is_a?(::Lutaml::Model::Serializable) && parent.class.attributes.key?(attr)

            Array(parent.public_send(attr))
          end
        end
      end
    end
  end
end