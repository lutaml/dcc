# frozen_string_literal: true

module Dcc::V3
  class List < CommonElements
    include ::Dcc::Base::List
  end
  Configuration.register_model(List, id: :list)
end
