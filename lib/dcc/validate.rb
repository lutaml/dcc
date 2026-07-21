# frozen_string_literal: true

# `Dcc::Validate` is the entry-point module for all validation services:
# XSD, Schematron, and Ruby-side business rules. Each service returns a
# `Dcc::Validate::Result` model that can be rendered as text, JSON, or YAML.
module Dcc
  module Validate
    autoload :Result, "dcc/validate/result"
    autoload :Issue, "dcc/validate/issue"
    autoload :Severity, "dcc/validate/severity"
    autoload :Xsd, "dcc/validate/xsd"
  end
end
