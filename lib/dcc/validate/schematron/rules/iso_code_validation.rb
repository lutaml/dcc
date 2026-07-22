# frozen_string_literal: true


module Dcc
  module Validate
    module Schematron
      module Rules
        # Validates ISO 3166-1 (country) and ISO 639-1 (language) codes used
        # in coreData. Custom type casts already enforce format; here we only
        # flag empties that escaped earlier casts.
        class IsoCodeValidation < Base
          def check_on(dcc)
            return [] unless dcc.respond_to?(:administrative_data)

            core = safe_attr(dcc.administrative_data, :core_data)
            return [] if core.nil?

            issues = []
            country = core.respond_to?(:country_code_iso_3166_1) ? core.country_code_iso_3166_1 : nil
            if country.nil? || country.to_s.empty?
              issues << issue(
                severity: :error,
                message: "dcc:countryCodeISO3166_1 is missing",
              )
            end

            used = core.respond_to?(:used_lang_code_iso_639_1) ? Array(core.used_lang_code_iso_639_1) : []
            issues << issue(
              severity: :error,
              message: "dcc:usedLangCodeISO639_1 must have at least one entry",
            ) if used.empty?

            mandatory = core.respond_to?(:mandatory_lang_code_iso_639_1) ? Array(core.mandatory_lang_code_iso_639_1) : []
            issues << issue(
              severity: :error,
              message: "dcc:mandatoryLangCodeISO639_1 must have at least one entry",
            ) if mandatory.empty?

            issues
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