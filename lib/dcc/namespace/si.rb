# frozen_string_literal: true

require "lutaml/xml"

module Dcc
  module Namespace
    # The D-SI XML namespace (https://ptb.de/si). Used to express measurement
    # quantities (real, complex, constant, list) and their uncertainties inside
    # DCC documents.
    #
    # Schema location is versioned. The default points to the latest D-SI
    # release; per-version overrides live in `Dcc::Si::V1::Namespace` and
    # `Dcc::Si::V2::Namespace`.
    class Si < Lutaml::Xml::Namespace
      uri "https://ptb.de/si"
      uri_aliases "https://ptb.de/si.xsd"
      schema_location "https://ptb.de/si/v2.2.1/SI_Format.xsd"
      prefix_default "si"
      element_form_default :qualified
      attribute_form_default :unqualified
      version "2.2.1"

      imports ::Dcc::Namespace::Qudt
    end
  end
end
