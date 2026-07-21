# frozen_string_literal: true

require "lutaml/xml"

module Dcc
  module Namespace
    # QUDT vocabulary namespace. Referenced by D-SI for quantity-kind
    # identifiers (e.g. `https://qudt.org/vocab/quantitykind/Length`).
    class Qudt < Lutaml::Xml::Namespace
      uri "http://qudt.org/vocab/"
      prefix_default "qudt"
      element_form_default :qualified
    end
  end
end
