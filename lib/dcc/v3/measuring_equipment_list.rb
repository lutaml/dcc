# frozen_string_literal: true

module Dcc::V3
  class MeasuringEquipmentList < CommonElements
    include ::Dcc::Base::MeasuringEquipmentList
  end
  Configuration.register_model(MeasuringEquipmentList, id: :measuringEquipments)
end
