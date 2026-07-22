# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates spacing in `*XMLList` attributes and elements: single
        # space between tokens, no leading/trailing space.
        class XmlListSpacing < Base
          def check_on(dcc)
            issues = []
            check_string_list_attribute(dcc, issues, :ref_type, "refType")
            issues
          end

          private

          def check_string_list_attribute(node, issues, attr, label)
            return unless node.is_a?(::Lutaml::Model::Serializable)

            if Dcc::TypeGuards.has_attribute?(node, attr)
              value = node.public_send(attr)
              value = value.to_s if value
              if value && !value.empty? && (value.start_with?(" ") || value.end_with?(" ") || value.match?(/\s\s/))
                issues << issue(
                  severity: :error,
                  message: "#{label} has invalid spacing: '#{value}'",
                )
              end
            end

            node.class.attributes.each_key do |a|
              v = node.public_send(a)
              Array(v).each { |child| check_string_list_attribute(child, issues, attr, label) }
            end
          end
        end
      end
    end
  end
end