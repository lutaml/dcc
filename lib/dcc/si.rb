# frozen_string_literal: true

# `Dcc::Si` is the D-SI quantity sub-namespace. It hosts the per-major-version
# wrapper hierarchies (`Dcc::Si::V1`, `Dcc::Si::V2`) that model the D-SI
# schema. Each version has its own type registry and configuration, mirroring
# the DCC pattern.
module Dcc
  module Si
    SUPPORTED_VERSIONS = [1, 2].freeze
    UNSPECIFIED_CONTEXT = ::Dcc::UNSPECIFIED_CONTEXT

    autoload :Namespace, "dcc/si/namespace"
    autoload :CommonElements, "dcc/si/common_elements"
    autoload :Base, "dcc/si/base"
    autoload :V1, "dcc/si/v1"
    autoload :V2, "dcc/si/v2"

    module_function

    def parse(input, version: 2, context: UNSPECIFIED_CONTEXT, register: nil)
      parser_for(version).parse(input, context: context, register: register)
    end

    def parser_for(version)
      case version.to_i
      when 1 then V1
      when 2 then V2
      else
        raise ::Dcc::UnknownVersionError,
              "Unsupported D-SI version: #{version.inspect} (expected 1 or 2)"
      end
    end
  end
end
