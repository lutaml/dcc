# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Errors if `endPerformanceDate` precedes `beginPerformanceDate`.
        class DateRangeCheck < Base
          def check_on(dcc)
            return [] unless dcc.respond_to?(:administrative_data)

            core = safe_attr(dcc.administrative_data, :core_data)
            return [] if core.nil?

            begin_d = core.respond_to?(:begin_performance_date) ? core.begin_performance_date : nil
            end_d = core.respond_to?(:end_performance_date) ? core.end_performance_date : nil

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
            return nil unless parent&.respond_to?(attr)

            parent.public_send(attr)
          end
        end
      end
    end
  end
end