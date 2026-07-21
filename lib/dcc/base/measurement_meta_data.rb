# frozen_string_literal: true

module Dcc
  module Base
    # `dcc:measurementMetaDataType` — single metadata statement block (a
    # specialized statement for measurement-level metadata).
    module MeasurementMetaData
      def self.included(klass)
        klass.class_eval do
          include ::Dcc::Base::Statement
        end
      end
    end
  end
end
