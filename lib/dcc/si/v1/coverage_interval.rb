# frozen_string_literal: true

module Dcc::Si::V1
  class CoverageInterval < CommonElements
    include ::Dcc::Si::Base::CoverageInterval
  end
  Configuration.register_model(CoverageInterval, id: :coverageInterval)
end
