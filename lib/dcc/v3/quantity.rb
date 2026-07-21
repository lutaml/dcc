# frozen_string_literal: true

module Dcc::V3
  class Quantity < CommonElements
    include ::Dcc::Base::Quantity
  end
  Configuration.register_model(Quantity, id: :quantity)
end
