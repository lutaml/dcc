# frozen_string_literal: true

module Dcc::Si::V1
  class MeasurementUncertaintyUnivariate < CommonElements
    include ::Dcc::Si::Base::MeasurementUncertaintyUnivariate
  end
  Configuration.register_model(MeasurementUncertaintyUnivariate, id: :measurementUncertaintyUnivariate)
end
