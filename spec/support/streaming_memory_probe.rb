# frozen_string_literal: true

# Memory probe for `Dcc::Streaming`. Run as a child process by
# `spec/dcc/streaming_spec.rb` so the suite's loaded state and RSpec's
# per-example retention cannot pollute the measurement. Prints one JSON
# object on stdout.
#
# It streams a document of uniformly sized items and samples the retained
# heap at two checkpoints. A reader that streams shows no growth between
# them; one that hoards models, DOM nodes or fragment strings shows growth
# proportional to the bytes it has seen.
#
# Both samples are taken inside the block, while the yielded item is still
# live, so each carries exactly one item's worth of objects. That is
# deliberate: the same bias sits in both checkpoints and cancels out of the
# comparison, and the resulting non-zero counts double as evidence the
# probe is measuring something at all.

require "objspace"
require "stringio"
require "json"
require "dcc"

PAD = ("z" * 4000).freeze
FIRST = 20
LAST = 200

def document
  body = (1..LAST).map do |i|
    %(<dcc:item id="i#{i}"><dcc:model>#{PAD}#{i}</dcc:model></dcc:item>)
  end.join
  root = %(xmlns:dcc="https://ptb.de/dcc" schemaVersion="3.3.0")
  %(<dcc:d #{root}>#{body}</dcc:d>)
end

def sample
  GC.start
  GC.start
  [ObjectSpace.memsize_of_all,
   ObjectSpace.each_object(Dcc::V3::Item).count,
   ObjectSpace.each_object(Moxml::Element).count]
end

marks = {}
seen = 0
Dcc::Streaming.each_item(StringIO.new(document)) do |_item|
  seen += 1
  marks[seen] = sample if [FIRST, LAST].include?(seen)
end

first = marks[FIRST]
last = marks[LAST]
streamed_kb = ((LAST - FIRST) * PAD.bytesize) / 1024.0

# Not an example group — this is a standalone program whose entire contract
# is printing the measurement to stdout for the parent process to parse.
# rubocop:disable RSpec/Output
puts({
  yielded: seen,
  heap_growth_kb: ((last[0] - first[0]) / 1024.0).round,
  budget_kb: (streamed_kb * 0.1).round,
  items_first: first[1],
  items_last: last[1],
  elements_first: first[2],
  elements_last: last[2],
}.to_json)
# rubocop:enable RSpec/Output
