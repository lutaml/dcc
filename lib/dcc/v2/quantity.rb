# frozen_string_literal: true

module Dcc::V2
  class Quantity < CommonElements
    include ::Dcc::Base::Quantity
  end
  Configuration.register_model(Quantity, id: :quantity)
end
