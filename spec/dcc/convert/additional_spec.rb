# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Convert::Yaml do
  before { Dcc::V3.load_all! }
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  it "produces valid YAML" do
    result = described_class.call(dcc)
    expect(result.format).to eq(:yaml)
    parsed = ::YAML.safe_load(result.payload, permitted_classes: [::Date, ::Time, ::DateTime])
    expect(parsed).to be_a(Hash)
  end

  it "includes schema_version" do
    parsed = ::YAML.safe_load(described_class.call(dcc).payload)
    expect(parsed["schemaVersion"]).to eq("3.3.0")
  end
end

RSpec.describe Dcc::Convert::Csv do
  before { Dcc::V3.load_all! }
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  it "emits a CSV with the header row" do
    payload = described_class.call(dcc).payload
    lines = payload.split("\n")
    expect(lines.first).to include("result_name")
    expect(lines.first).to include("quantity_name")
  end
end

RSpec.describe Dcc::Convert::Html do
  before { Dcc::V3.load_all! }
  let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml"))) }

  it "emits a valid HTML document" do
    payload = described_class.call(dcc).payload
    expect(payload).to start_with("<!DOCTYPE html>")
    expect(payload).to include("<html")
    expect(payload).to include("</html>")
    expect(payload).to include("1234")
    expect(payload).to include("DE")
  end
end