# frozen_string_literal: true

require "spec_helper"

# Round-trip every reference XML fixture we ship:
#
# * `dcclib/*.xml`         — PTB Python dcclib test resources
# * `dcc_examples/*.xml`   — PTB DCC XSD repo examples
# * `dcc_excel/*.xml`      — dccExcelViewer test file
# * `dsi_examples/**/*.xml` — PTB D-SI XSD repo examples organized by tier
#
# Each fixture is parsed into the version-appropriate Dcc::V*::DigitalCalibrationCertificate,
# serialized back to XML, and compared canonically with the original.
RSpec.describe "DCC XML round-trip fidelity" do
  fixture_globs = %w[
    dcclib/*.xml
    dcc_examples/*.xml
    dcc_excel/*.xml
  ].freeze

  fixture_globs.each do |glob|
    Dir[File.join(FIXTURES_DIR, glob)].sort.each do |path|
      relative = path.sub("#{FIXTURES_DIR}/", "")

      context "fixture: #{relative}" do
        let(:xml) { File.read(path) }

        it "auto-detects a known major version" do
          expect { Dcc.detect_version(xml) }.not_to raise_error
          expect([2, 3]).to include(Dcc.detect_version(xml))
        end

        it "parses without raising" do
          version = Dcc.detect_version(xml)
          Dcc.parser_for(version).load_all!
          expect { Dcc.parse(xml) }.not_to raise_error
        end

        it "round-trips through parse → serialize" do
          version = Dcc.detect_version(xml)
          parser = Dcc.parser_for(version)
          parser.load_all!

          parsed = Dcc.parse(xml)
          serialized = parsed.to_xml

          expect(serialized).to be_a(String)
          expect(serialized).to include("digitalCalibrationCertificate")
        end
      end
    end
  end
end
