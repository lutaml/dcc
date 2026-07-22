# frozen_string_literal: true

module Dcc::Si::V1
  class ExpandedUncXmlList < CommonElements
    include ::Dcc::Si::Base::ExpandedUncXmlList
  end
  Configuration.register_model(ExpandedUncXmlList, id: :expandedUncXMLList)
end
