# frozen_string_literal: true

module Dcc::V2
  class Item < CommonElements
    include ::Dcc::Base::Item
  end
  Configuration.register_model(Item, id: :item)
end
