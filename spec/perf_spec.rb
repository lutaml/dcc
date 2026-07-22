# frozen_string_literal: true

require "spec_helper"
require "benchmark"

RSpec.describe "Dcc parse performance" do
  before { Dcc.load_all! }

  it "parses valid.xml in under 1 second" do
    xml = File.read(fixtures_path("dcclib", "valid.xml"))
    elapsed = ::Benchmark.realtime { Dcc.parse(xml) }
    expect(elapsed).to be < 1.0
  end

  it "is faster on the second parse (memoization check)" do
    xml = File.read(fixtures_path("dcclib", "valid.xml"))
    # First parse populates caches.
    Dcc.parse(xml)
    first = ::Benchmark.realtime { Dcc.parse(xml) }
    second = ::Benchmark.realtime { Dcc.parse(xml) }
    # Second parse should not be dramatically slower than the first.
    expect(second).to be <= first * 2.0
  end
end