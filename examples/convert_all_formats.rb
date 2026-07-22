#!/usr/bin/env ruby
# frozen_string_literal: true

# Convert a DCC XML file to JSON, YAML, CSV, and HTML in one go.
#
# Usage:
#   bundle exec examples/convert_all_formats.rb path/to/dcc.xml

require "dcc"

path = ARGV[0] || File.expand_path("../spec/fixtures/dcclib/valid.xml", __dir__)
dcc = Dcc.parse(File.read(path))

[Dcc::Convert::Json, Dcc::Convert::Yaml, Dcc::Convert::Csv, Dcc::Convert::Html].each do |service|
  result = service.call(dcc)
  puts "== #{service.name.split('::').last} =="
  puts result.to_s[0, 200] + "..."
  puts
end
