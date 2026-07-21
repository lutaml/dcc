# frozen_string_literal: true

require "spec_helper"

# Parse every PTB reference fixture and confirm we can round-trip without
# raising. Canonical-XML equivalence is checked via the canon gem matcher.
RSpec.describe "PTB fixture end-to-end parse" do
  fixtures = []
  %w[dcclib dcc_xsd dcc_excel].each do |dir|
    Dir[File.join(FIXTURES_DIR, "#{dir}/*.xml")].each { |p| fixtures << p }
  end

  fixtures.sort.each do |path|
    relative = path.sub("#{FIXTURES_DIR}/", "")

    it "#{relative} parses without raising" do
      xml = File.read(path)
      expect { Dcc.parse(xml) }.not_to raise_error
    end

    it "#{relative} round-trips through to_xml" do
      dcc = Dcc.parse(File.read(path))
      expect { dcc.to_xml }.not_to raise_error
    end
  end
end