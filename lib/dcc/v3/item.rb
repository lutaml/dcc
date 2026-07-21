# frozen_string_literal: true

module Dcc::V3
  class Item < CommonElements
    include ::Dcc::Base::Item
  end
  Configuration.register_model(Item, id: :item)
end
