# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # `dcc:influenceConditions` must appear somewhere (global, list, or
        # quantity level). Error if missing.
        class InfluenceConditionsPlacement < Base
          def check_on(dcc)
            return [] unless dcc.respond_to?(:measurement_results)

            mr_list = safe_attr(dcc.measurement_results, :measurement_result)
            return [] if mr_list.empty?

            any_present = mr_list.any? do |mr|
              next false unless mr.respond_to?(:influence_conditions)
              next true unless mr.influence_conditions.nil?

              mr.respond_to?(:results) && mr.results &&
                has_in_descendants?(mr.results)
            end

            any_present ? [] : [
              issue(
                severity: :error,
                message: "dcc:influenceConditions is missing everywhere",
              ),
            ]
          end

          private

          def has_in_descendants?(node)
            return false unless node.is_a?(::Lutaml::Model::Serializable)

            if node.respond_to?(:influence_conditions) && !node.influence_conditions.nil?
              return true
            end

            node.class.attributes.each_key do |attr|
              value = node.public_send(attr)
              Array(value).any? { |c| has_in_descendants?(c) } if value.is_a?(::Array) || value.is_a?(::Lutaml::Model::Serializable)
            end
            false
          end

          def safe_attr(parent, attr)
            return [] unless parent&.respond_to?(attr)

            Array(parent.public_send(attr))
          end
        end
      end
    end
  end
end