# frozen_string_literal: true

module Dcc::Si::V2
  class RealListXmlList < CommonElements
    include ::Dcc::Si::Base::RealListXmlList
  end
  Configuration.register_model(RealListXmlList, id: :realListXMLList)
end
