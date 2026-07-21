# frozen_string_literal: true

module Dcc::V3
  class MeasurementResultList < CommonElements
    include ::Dcc::Base::MeasurementResultList
  end
  Configuration.register_model(MeasurementResultList, id: :measurementResults)
end
