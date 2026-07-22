#!/usr/bin/env ruby
# frozen_string_literal: true

# Build a minimal DCC programmatically using the Builder DSL.
#
# Usage:
#   bundle exec examples/build_minimal_dcc.rb

require "dcc"

dcc = Dcc.build(version: 3) do
  administrative_data do
    core_data do
      unique_identifier "urn:uuid:00000000-0000-0000-0000-000000000001"
      country_code "DE"
      used_lang "en"
      mandatory_lang "en"
    end
    items { item(model: "Demo Pt100") }
  end
end

puts dcc.to_xml
