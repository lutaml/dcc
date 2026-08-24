# frozen_string_literal: true

module Dcc::Si::V2
  class ExpandedUnc < CommonElements
    include ::Dcc::Si::Base::ExpandedUnc
  end
  Configuration.register_model(ExpandedUnc, id: :expandedUnc)
end
