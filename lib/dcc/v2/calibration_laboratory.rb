# frozen_string_literal: true

module Dcc::V2
  class CalibrationLaboratory < CommonElements
    include ::Dcc::Base::CalibrationLaboratory
  end
  Configuration.register_model(CalibrationLaboratory, id: :calibrationLaboratory)
end
