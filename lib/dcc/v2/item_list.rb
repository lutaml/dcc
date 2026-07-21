# frozen_string_literal: true

module Dcc::V2
  class ItemList < CommonElements
    include ::Dcc::Base::ItemList
  end
  Configuration.register_model(ItemList, id: :items)
end
