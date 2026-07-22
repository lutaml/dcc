# frozen_string_literal: true

module Dcc::Si::V1
  class ComplexListXmlList < CommonElements
    include ::Dcc::Si::Base::ComplexListXmlList
  end
  Configuration.register_model(ComplexListXmlList, id: :complexListXMLList)
end
