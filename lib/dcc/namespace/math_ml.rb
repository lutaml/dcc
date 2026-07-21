# frozen_string_literal: true

require "lutaml/xml"

module Dcc
  module Namespace
    # W3C MathML namespace used inside DCC `dcc:formula` elements.
    class MathMl < Lutaml::Xml::Namespace
      uri "http://www.w3.org/1998/Math/MathML"
      prefix_default "ml"
      element_form_default :qualified
    end
  end
end
