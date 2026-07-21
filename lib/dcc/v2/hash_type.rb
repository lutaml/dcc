# frozen_string_literal: true

module Dcc::V2
  class HashType < CommonElements
    include ::Dcc::Base::HashType
  end
  Configuration.register_model(HashType, id: :previousReport)
end
