# frozen_string_literal: true

module Dcc::V2
  class RespPerson < CommonElements
    include ::Dcc::Base::RespPerson
  end
  Configuration.register_model(RespPerson, id: :respPerson)
end
