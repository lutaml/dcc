# frozen_string_literal: true

require_relative "base"

module Dcc
  module Validate
    module Schematron
      module Rules
        # Errors on duplicate language codes in `dcc:usedLangCodeISO639_1`.
        class LanguageCodeDedup < Base
          def check_on(dcc)
            return [] unless dcc.respond_to?(:administrative_data)

            core = safe_attr(dcc.administrative_data, :core_data)
            return [] if core.nil?

            used = core.respond_to?(:used_lang_code_iso_639_1) ? Array(core.used_lang_code_iso_639_1) : []
            used_strings = used.map(&:to_s)
            duplicates = used_strings.group_by(&:itself).select { |_k, v| v.size > 1 }.keys

            duplicates.map do |dup|
              issue(
                severity: :error,
                message: "dcc:usedLangCodeISO639_1 contains duplicate '#{dup}'",
              )
            end
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