# frozen_string_literal: true

# `Dcc::Convert` is the entry-point module for format converters. Each
# converter accepts a parsed DCC object tree and returns a `Dcc::Convert::Result`
# model that can be rendered as text, JSON, or YAML.
module Dcc
  module Convert
    autoload :Result, "dcc/convert/result"
    autoload :Json, "dcc/convert/json"
  end
end