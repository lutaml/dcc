# frozen_string_literal: true

module Dcc::V2
  class MeasurementResultList < CommonElements
    include ::Dcc::Base::MeasurementResultList
  end
  Configuration.register_model(MeasurementResultList, id: :measurementResults)
end
