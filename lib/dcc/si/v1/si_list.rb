# frozen_string_literal: true

module Dcc::Si::V1
  class SiList < CommonElements
    include ::Dcc::Si::Base::SiList
  end
  Configuration.register_model(SiList, id: :list)
end
