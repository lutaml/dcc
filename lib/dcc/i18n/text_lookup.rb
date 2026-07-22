# frozen_string_literal: true

module Dcc
  module I18n
    # `Dcc::I18n::TextLookup` extracts the best-matching localized string
    # from a `dcc:textType` block.
    #
    # Selection order:
    #   1. Exact match for the requested language
    #   2. First mandatory language declared in the DCC coreData
    #   3. First used language declared in the DCC coreData
    #   4. First content element regardless of language
    #   5. nil if no content at all
    module TextLookup
      class << self
        # @param text_obj [Object, nil] a parsed `dcc:textType` block.
        # @param dcc [Object, nil] the parent DCC (used to read declared langs).
        # @param lang [String, nil] requested ISO 639-1 code.
        # @return [String, nil]
        def call(text_obj, dcc: nil, lang: nil)
          return nil unless text_obj && text_obj.respond_to?(:content)

          contents = Array(text_obj.content)
          return nil if contents.empty?

          return content_value(contents, lang) if lang

          dcc_langs = declared_languages(dcc)
          dcc_langs.each do |fallback|
            val = content_value(contents, fallback)
            return val if val
          end

          content_value(contents, nil)
        end

        private

        def content_value(contents, lang)
          match = if lang
                    contents.find { |c| c.lang.to_s == lang.to_s }
                  else
                    contents.first
                  end
          return nil unless match

          values = Array(match.value)
          values.first&.to_s
        end

        def declared_languages(dcc)
          return [] unless dcc && dcc.respond_to?(:administrative_data)

          admin = dcc.administrative_data
          return [] unless admin&.respond_to?(:core_data)

          core = admin.core_data
          return [] unless core

          mandatory = Array(core.mandatory_lang_code_iso_639_1).map(&:to_s)
          used = Array(core.used_lang_code_iso_639_1).map(&:to_s)
          (mandatory + used).uniq
        end
      end
    end
  end
end