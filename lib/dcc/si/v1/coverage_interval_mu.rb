# frozen_string_literal: true

module Dcc::Si::V1
  class CoverageIntervalMU < CommonElements
    include ::Dcc::Si::Base::CoverageIntervalMU
  end
  Configuration.register_model(CoverageIntervalMU, id: :coverageIntervalMU)
end
