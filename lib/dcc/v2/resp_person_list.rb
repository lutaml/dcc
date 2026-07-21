# frozen_string_literal: true

module Dcc::V2
  class RespPersonList < CommonElements
    include ::Dcc::Base::RespPersonList
  end
  Configuration.register_model(RespPersonList, id: :respPersons)
end
