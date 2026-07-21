# frozen_string_literal: true

module Dcc
  module Si
    module V2
      autoload :Configuration, "dcc/si/v2/configuration"
      autoload :CommonElements, "dcc/si/v2/common_elements"
      autoload :Namespace, "dcc/si/v2/namespace"

      ROOT_ELEMENT_TAG = "real"

      extend ::Dcc::VersionedParser
    end
  end
end
