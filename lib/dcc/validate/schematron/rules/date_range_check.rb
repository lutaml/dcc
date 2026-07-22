# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Errors if `endPerformanceDate` precedes `beginPerformanceDate`.
        class DateRangeCheck < Base
          def check_on(dcc)
            return [] unless Dcc::TypeGuards.has_attribute?(dcc, :administrative_data)

            core = safe_attr(dcc.administrative_data, :core_data)
            return [] if core.nil?

            begin_d = Dcc::TypeGuards.has_attribute?(core, :begin_performance_date) ? core.begin_performance_date : nil
            end_d = Dcc::TypeGuards.has_attribute?(core, :end_performance_date) ? core.end_performance_date : nil

            return [] if begin_d.nil? || end_d.nil?
            return [] unless end_d < begin_d

            [
              issue(
                severity: :error,
                message: "endPerformanceDate (#{end_d}) precedes beginPerformanceDate (#{begin_d})",
              ),
            ]
          end

          private

          def safe_attr(parent, attr)
            return nil unless parent && parent.is_a?(::Lutaml::Model::Serializable) && parent.class.attributes.key?(attr)

            parent.public_send(attr)
          end
        end
      end
    end
  end
end