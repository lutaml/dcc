# frozen_string_literal: true

module Dcc::V2
  class List < CommonElements
    include ::Dcc::Base::List
  end
  Configuration.register_model(List, id: :list)
end
