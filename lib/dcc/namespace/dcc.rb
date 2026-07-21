# frozen_string_literal: true

require "lutaml/xml"

module Dcc
  module Namespace
    # The DCC XML namespace. PTB publishes the canonical URI as
    # `https://ptb.de/dcc`; older documents occasionally use the
    # `https://ptb.de/dcc.xsd` alias which we accept via `uri_aliases`.
    #
    # Schema location is versioned (e.g. `https://ptb.de/dcc/v3.3.0/dcc.xsd`).
    # The default points to the latest published version; per-version overrides
    # happen in `Dcc::V2::Namespace` and `Dcc::V3::Namespace`.
    class Dcc < Lutaml::Xml::Namespace
      uri "https://ptb.de/dcc"
      uri_aliases "https://ptb.de/dcc.xsd"
      schema_location "https://ptb.de/dcc/v3.3.0/dcc.xsd"
      prefix_default "dcc"
      element_form_default :qualified
      attribute_form_default :unqualified
      version "3.3.0"

      # DCC imports D-SI for quantity expressions, MathML for formulae, and
      # (from v3.4.0) W3C XMLDSig for digital signatures.
      imports ::Dcc::Namespace::Si,
              ::Dcc::Namespace::MathMl,
              ::Dcc::Namespace::Dsig
    end
  end
end
