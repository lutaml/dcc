# frozen_string_literal: true

module Dcc::V3
  class CoreData < CommonElements
    include ::Dcc::Base::CoreData
  end
  Configuration.register_model(CoreData, id: :coreData)
end
