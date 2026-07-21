# frozen_string_literal: true

module Dcc::V2
  class AdministrativeData < CommonElements
    include ::Dcc::Base::AdministrativeData
  end
  Configuration.register_model(AdministrativeData, id: :administrativeData)
end
