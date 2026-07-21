# frozen_string_literal: true

module Dcc::V2
  class MeasurementMetaDataList < CommonElements
    include ::Dcc::Base::MeasurementMetaDataList
  end
  Configuration.register_model(MeasurementMetaDataList, id: :measurementMetaData)
end
