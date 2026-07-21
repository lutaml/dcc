# frozen_string_literal: true

module Dcc::V2
  class Data < CommonElements
    include ::Dcc::Base::Data
  end
  Configuration.register_model(Data, id: :data)
end
