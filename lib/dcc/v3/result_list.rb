# frozen_string_literal: true

module Dcc::V3
  class ResultList < CommonElements
    include ::Dcc::Base::ResultList
  end
  Configuration.register_model(ResultList, id: :results)
end
