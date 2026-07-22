# frozen_string_literal: true

require "rexml/parsers/pullparser"

module Dcc
  # `Dcc::Streaming` provides lazy enumeration of items, results, and
  # quantities in large DCC documents. Uses REXML's pull parser (stdlib)
  # so the document is never fully loaded into memory — Nokogiri is
  # banned outside `Dcc::Validate::Xsd` per project rule.
  #
  # Each yielded value is a parsed `Dcc::V2::*` or `Dcc::V3::*` object
  # constructed from the matched subtree, so callers get typed access
  # without paying for the full document tree.
  module Streaming
    autoload :Reader, "dcc/streaming/reader"
  end
end