# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Migrate do
  before { Dcc.load_all! }

  it "rewrites schemaVersion within the same major" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    migrated = described_class.call(dcc, from: "3.3.0", to: "3.2.1")
    expect(migrated.schema_version.to_s).to eq("3.2.1")
  end

  it "raises UnknownVersionError for unsupported target" do
    dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
    expect { described_class.call(dcc, from: "3.3.0", to: "9.9.9") }
      .to raise_error(::Dcc::UnknownVersionError, /Unsupported DCC version/)
  end
end