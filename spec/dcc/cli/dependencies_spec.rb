# frozen_string_literal: true

require "spec_helper"

# The CLI ships as `exe/dcc`. Every gem it requires unconditionally must be a
# declared runtime dependency, or `gem install dcc` yields a binary that
# crashes on every command. A gem may be left undeclared only by naming it
# in `optional`, which means its require is guarded and its absence degrades
# the output instead of raising.
# rubocop:disable RSpec/DescribeClass -- packaging invariant, not a class
RSpec.describe "dcc CLI runtime dependencies" do
  let(:root) { File.expand_path("../../..", __dir__) }
  let(:gemspec) { Gem::Specification.load(File.join(root, "dcc.gemspec")) }
  let(:declared) { gemspec.runtime_dependencies.map(&:name) }
  # Matches indented requires (inside a method or conditional) and both quote
  # styles. Does not match parenthesized, multiline, or interpolated requires
  # -- add one of those and this guard will not see it.
  let(:required) do
    pattern = /^\s*require ["']([^"']+)["']/
    Dir[File.join(root, "lib", "dcc", "cli", "**", "*.rb")]
      .flat_map { |f| File.read(f).scan(pattern).flatten }
      .reject { |name| name.start_with?("dcc/") }
      .map { |name| name.split("/").first }
      .uniq - stdlib
  end

  # Plain methods, not `let`, to stay under the memoized-helper limit.
  def stdlib
    %w[base64 bigdecimal csv date digest json open3 openssl set stringio yaml]
  end

  # `tty-table` costs eight further gems to prettify one command. Every
  # library user would install them to parse XML. `formatters.rb` guards the
  # require and falls back to its plain renderer instead.
  def optional
    %w[tty-table]
  end

  it "finds the gems the CLI requires" do
    expect(required).to include("thor", "tty-table")
  end

  it "declares every third-party gem the CLI requires" do
    expect(required - declared - optional).to be_empty
  end

  it "keeps the optional gems out of the gemspec" do
    expect(declared).not_to include(*optional)
  end
end
# rubocop:enable RSpec/DescribeClass
