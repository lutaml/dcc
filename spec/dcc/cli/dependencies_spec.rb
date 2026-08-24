# frozen_string_literal: true

require "spec_helper"

# Every gem `lib/` requires unconditionally must be a declared runtime
# dependency, or `gem install dcc` yields a library that crashes on load.
# A gem may be left undeclared only when its require is guarded (indented
# inside a method or conditional) AND it is named in `optional`, meaning its
# absence degrades the output instead of raising.
# rubocop:disable RSpec/DescribeClass -- packaging invariant, not a class
RSpec.describe "dcc runtime dependencies" do
  let(:root) { File.expand_path("../../..", __dir__) }
  let(:gemspec) { Gem::Specification.load(File.join(root, "dcc.gemspec")) }
  let(:declared) { gemspec.runtime_dependencies.map(&:name) }

  # Requires at column 0 run unconditionally when the file is loaded; the
  # `optional` escape hatch never applies to them. Does not match
  # parenthesized, multiline, or interpolated requires -- add one of those
  # and this guard will not see it.
  let(:unguarded) { scan(/^require ["']([^"']+)["']/) }

  # Indented requires sit inside a method or conditional, so a rescue can
  # turn a missing gem into degraded output instead of a crash.
  let(:guarded) { scan(/^[ \t]+require ["']([^"']+)["']/) }

  def scan(pattern)
    Dir[File.join(root, "lib", "**", "*.rb")]
      .flat_map { |f| File.read(f).scan(pattern).flatten }
      .reject { |name| name == "dcc" || name.start_with?("dcc/") }
      .map { |name| gem_for(name) }
      .uniq - stdlib
  end

  # Require paths whose gem name is not simply the first path segment.
  def gem_for(path)
    {
      "lutaml/model" => "lutaml-model",
      # lutaml-model also ships the lutaml/xml require path.
      "lutaml/xml" => "lutaml-model",
      "sinatra/base" => "sinatra",
    }.fetch(path) { path.split("/").first }
  end

  # Plain methods, not `let`, to stay under the memoized-helper limit.
  # `csv` and `base64` are NOT here: they stopped being default gems in
  # Ruby 3.4, so requiring them makes them real runtime dependencies.
  def stdlib
    %w[bigdecimal date digest json open3 openssl set stringio yaml]
  end

  # `tty-table` costs eight further gems to prettify one command, and
  # `sinatra` serves only the opt-in REST API. Their requires are guarded
  # and fall back to plain output / a clear error instead of crashing.
  def optional
    %w[sinatra tty-table]
  end

  it "finds the gems the library requires" do
    expect(unguarded).to include("thor", "nokogiri")
    expect(guarded).to include("tty-table")
  end

  it "declares every gem required unconditionally at the top of a file" do
    expect(unguarded - declared).to be_empty
  end

  it "declares every guarded require unless it is deliberately optional" do
    expect(guarded - declared - optional).to be_empty
  end

  it "keeps the optional gems out of the gemspec" do
    expect(declared).not_to include(*optional)
  end
end
# rubocop:enable RSpec/DescribeClass
