# frozen_string_literal: true

module Dcc
  module Extract
    # The "Ring" of a `dcc:byteDataType` element: which section of the DCC
    # document contained it. PTB defines these as `administrativeData`,
    # `measurementResults`, `comment`, and `document`.
    module Ring
      ADMINISTRATIVE_DATA = :administrativeData
      MEASUREMENT_RESULTS = :measurementResults
      COMMENT = :comment
      DOCUMENT = :document

      ALL = [ADMINISTRATIVE_DATA, MEASUREMENT_RESULTS, COMMENT, DOCUMENT].freeze

      class << self
        # @param symbol_or_string [Symbol, String, nil]
        # @return [Symbol, nil] the canonical ring symbol.
        def normalize(symbol_or_string)
          return nil if symbol_or_string.nil?

          sym = symbol_or_string.to_sym
          ALL.include?(sym) ? sym : nil
        end
      end
    end
  end
end