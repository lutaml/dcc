# frozen_string_literal: true

module Dcc::V2
  class ResultList < CommonElements
    include ::Dcc::Base::ResultList
  end
  Configuration.register_model(ResultList, id: :results)
end
