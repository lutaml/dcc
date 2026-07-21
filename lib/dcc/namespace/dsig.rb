# frozen_string_literal: true

require "lutaml/xml"

module Dcc
  module Namespace
    # W3C XML Digital Signature namespace. Imported by DCC v3.4.0+ to support
    # `ds:Signature` elements on the root `digitalCalibrationCertificate`.
    class Dsig < Lutaml::Xml::Namespace
      uri "http://www.w3.org/2000/09/xmldsig#"
      prefix_default "ds"
      element_form_default :qualified
    end
  end
end
