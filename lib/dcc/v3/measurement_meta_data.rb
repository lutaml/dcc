# frozen_string_literal: true

module Dcc::V3
  class MeasurementMetaData < CommonElements
    include ::Dcc::Base::MeasurementMetaData
  end
  Configuration.register_model(MeasurementMetaData, id: :metaData)
end
