# frozen_string_literal: true

module Dcc
  module Si
    module V1
      autoload :Configuration, "dcc/si/v1/configuration"
      autoload :CommonElements, "dcc/si/v1/common_elements"
      autoload :Namespace, "dcc/si/v1/namespace"

      ROOT_ELEMENT_TAG = "real"

      extend ::Dcc::VersionedParser
    end
  end
end
