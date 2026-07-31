# frozen_string_literal: true

require "spec_helper"

# The CLI ships as `exe/dcc`. Every gem it requires at load time must be a
# declared runtime dependency, or `gem install dcc` yields a binary that
# crashes on every command.
# rubocop:disable RSpec/DescribeClass -- packaging invariant, not a class
RSpec.describe "dcc CLI runtime dependencies" do
  let(:root) { File.expand_path("../../..", __dir__) }
  let(:gemspec) { Gem::Specification.load(File.join(root, "dcc.gemspec")) }
  let(:declared) { gemspec.runtime_dependencies.map(&:name) }
  let(:stdlib) do
    %w[base64 bigdecimal csv date digest json open3 openssl set stringio yaml]
  end

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

  it "finds the gems the CLI requires" do
    expect(required).to include("thor", "tty-table")
  end

  it "declares every third-party gem the CLI requires" do
    expect(required - declared).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
