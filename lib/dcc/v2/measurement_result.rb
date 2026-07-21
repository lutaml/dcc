# frozen_string_literal: true

module Dcc::V2
  class MeasurementResult < CommonElements
    include ::Dcc::Base::MeasurementResult
  end
  Configuration.register_model(MeasurementResult, id: :measurementResult)
end
