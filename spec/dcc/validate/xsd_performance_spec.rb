# frozen_string_literal: true

require "spec_helper"

# Regression guard for the schema memoization in `Dcc::Validate::Xsd`.
#
# Asserts no timing on purpose — a wall-clock benchmark would be
# machine-dependent and flaky in CI. What these examples establish is that one
# `Nokogiri::XML::Schema` gets built per distinct version, that a lookup returns
# the schema stored under the version it asked for, and that looking the same
# version up again — explicitly or via `:auto` — neither rebuilds it nor adds a
# cache entry.
RSpec.describe Dcc::Validate::Xsd do
  let(:xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
  let(:cache) { described_class::SCHEMA_CACHE }
  let(:builds) { [] }

  # Records every real schema construction, letting each one through. Only the
  # count is ever read, so store a marker rather than the argument — that
  # argument is the resolved XSD, about 50 KB each time.
  def track_builds
    allow(Nokogiri::XML::Schema)
      .to receive(:new).and_wrap_original do |original, *args, **kwargs|
        builds << :built
        original.call(*args, **kwargs)
      end
  end

  # `SCHEMA_CACHE` is process-wide. Start cold, then hand the suite back
  # exactly the entries it had.
  around do |example|
    warm = cache.dup
    cache.clear
    example.run
  ensure
    cache.replace(warm)
  end

  # The build count and the cache keys are asserted together on purpose. Two
  # builds alone would also match one version built twice; the keys say which
  # two were built. `.with` cannot discriminate here — the argument is the XSD
  # document, not the version.
  it "builds one schema per distinct version" do
    track_builds

    3.times { described_class.call(xml, version: "3.3.0") }
    2.times { described_class.call(xml, version: "3.2.0") }

    expect([builds.size, cache.keys]).to eq([2, %w[3.3.0 3.2.0]])
  end

  it "hands back the schema cached under the requested version" do
    versions = %w[3.3.0 3.2.0]
    versions.each { |version| described_class.call(xml, version: version) }

    looked_up = versions.to_h { |v| [v, described_class.send(:schema_for, v)] }

    expect(looked_up).to eq(versions.to_h { |v| [v, cache.fetch(v)] })
  end

  # Both examples warm the cache first and only then start counting, so any
  # build recorded here is a cache miss. The keys are asserted alongside the
  # count, so a rebuild that overwrote the entry fails too. Counting the cold
  # build is the first example's job. This one pins the explicit-version path,
  # the next one pins `:auto`.
  it "reuses the cached schema when the same version is looked up again" do
    described_class.call(xml, version: "3.3.0")
    track_builds

    3.times { described_class.call(xml, version: "3.3.0") }

    expect([builds.size, cache.keys]).to eq([0, %w[3.3.0]])
  end

  it "reuses the cached schema when the version is auto-detected" do
    described_class.call(xml, version: "3.3.0")
    track_builds

    3.times { described_class.call(xml) }

    expect([builds.size, cache.keys]).to eq([0, %w[3.3.0]])
  end
end
