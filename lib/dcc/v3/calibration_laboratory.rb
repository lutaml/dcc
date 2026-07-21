# frozen_string_literal: true

module Dcc::V3
  class CalibrationLaboratory < CommonElements
    include ::Dcc::Base::CalibrationLaboratory
  end
  Configuration.register_model(CalibrationLaboratory, id: :calibrationLaboratory)
end
