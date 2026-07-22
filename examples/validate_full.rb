#!/usr/bin/env ruby
# frozen_string_literal: true

# Validate a DCC against XSD, Schematron, and business rules in one shot.
#
# Usage:
#   bundle exec examples/validate_full.rb path/to/dcc.xml

require "dcc"

path = ARGV[0] || File.expand_path("../spec/fixtures/dcclib/valid.xml", __dir__)
xml = File.read(path)

dcc = Dcc.parse(xml)

[Dcc::Validate::Xsd,
 Dcc::Validate::Schematron,
 Dcc::Validate::BusinessRules].each do |service|
  result =
    case service.name
    when "Dcc::Validate::Xsd" then service.call(xml)
    else service.call(dcc)
    end
  puts "== #{service.name} =="
  puts result.to_s
  puts
end
