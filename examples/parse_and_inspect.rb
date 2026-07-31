#!/usr/bin/env ruby
# frozen_string_literal: true

# Parse a DCC XML file and print the uniqueIdentifier + country.
#
# Usage:
#   bundle exec examples/parse_and_inspect.rb path/to/dcc.xml

require "dcc"

path = ARGV[0] || File.expand_path("../spec/fixtures/dcclib/valid.xml", __dir__)
dcc = Dcc.parse(File.read(path))

puts "Class:               #{dcc.class.name}"
puts "Schema version:      #{dcc.schema_version}"
puts "Unique identifier:   #{dcc.administrative_data.core_data.unique_identifier}"
puts "Country:             #{dcc.administrative_data.core_data.country_code_iso_3166_1}"
puts "Items:               #{dcc.administrative_data.items.item.size}"
puts "Measurement results: #{dcc.measurement_results.measurement_result.size}"
