# frozen_string_literal: true

# `Dcc::I18n` provides helpers for navigating multilingual DCC content.
# PTB DCC documents carry `usedLangCodeISO639_1` and
# `mandatoryLangCodeISO639_1` attributes; text blocks (`dcc:textType`)
# contain one `dcc:content` element per language. These helpers pick the
# best-matching language with a configurable fallback chain.
module Dcc
  module I18n
    autoload :TextLookup, "dcc/i18n/text_lookup"
  end
end