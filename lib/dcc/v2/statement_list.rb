# frozen_string_literal: true

module Dcc::V2
  class StatementList < CommonElements
    include ::Dcc::Base::StatementList
  end
  Configuration.register_model(StatementList, id: :statements)
end
