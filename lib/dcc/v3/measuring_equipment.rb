# frozen_string_literal: true

module Dcc::V3
  class MeasuringEquipment < CommonElements
    include ::Dcc::Base::MeasuringEquipment
  end
  Configuration.register_model(MeasuringEquipment, id: :measuringEquipment)
end
