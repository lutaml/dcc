# frozen_string_literal: true

# `Dcc::QuantityFormat` renders quantities in human-readable form. Three
# formats: `:short` (compact, e.g. `42.00(5) K`), `:long` (verbose), and
# `:latex` (siunitx).
module Dcc
  module QuantityFormat
    autoload :Formatter, "dcc/quantity_format/formatter"
  end
end