# frozen_string_literal: true

module Dcc::V2
  class EquipmentClass < CommonElements
    include ::Dcc::Base::EquipmentClass
  end
  Configuration.register_model(EquipmentClass, id: :equipmentClass)
end
