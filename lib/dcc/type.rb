# frozen_string_literal: true

# `Dcc::Type` hosts the gem's custom `Lutaml::Model::Type::Value` subclasses.
# These encode XML-level constraints (ISO code patterns, siunitx unit grammar,
# base64 binary, space-separated decimal lists) that the framework's built-in
# types do not cover.
module Dcc
  module Type
    autoload :IsoCountryCode, "dcc/type/iso_country_code"
    autoload :IsoLanguageCode, "dcc/type/iso_language_code"
    autoload :SiUnit, "dcc/type/si_unit"
    autoload :DecimalXmlList, "dcc/type/decimal_xml_list"
    autoload :Base64Binary, "dcc/type/base64_binary"
    autoload :SchemaVersion, "dcc/type/schema_version"
  end
end
