# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::Xsd do
  describe ".call" do
    let(:valid_xml) { File.read(fixtures_path("dcclib", "valid.xml")) }
    let(:invalid_schema_xml) { File.read(fixtures_path("dcclib", "invalid_schema.xml")) }

    it "accepts a valid document against auto-detected version" do
      result = described_class.call(valid_xml)
      expect(result.ok?).to be(true), "Expected valid.xml to pass XSD validation, got:\n#{result}"
      expect(result.schema_version).to eq("3.3.0")
      expect(result.source).to eq("xsd")
    end

    it "accepts an explicit version override" do
      result = described_class.call(valid_xml, version: "3.3.0")
      expect(result.ok?).to be(true)
    end

    it "detects XSD violations" do
      result = described_class.call(invalid_schema_xml)
      expect(result.ok?).to be(false)
      expect(result.errors).not_to be_empty
      expect(result.errors.first).to be_a(Dcc::Validate::Issue)
      expect(result.errors.first.severity).to eq(:error)
      expect(result.errors.first.line).to be_a(Integer)
      expect(result.errors.first.source).to eq("xsd")
    end

    it "caches the loaded schema" do
      described_class.call(valid_xml)
      cache_before = described_class.const_get(:SCHEMA_CACHE).size
      described_class.call(valid_xml)
      expect(described_class.const_get(:SCHEMA_CACHE).size).to eq(cache_before)
    end
  end
end

RSpec.describe Dcc::Validate::Severity do
  describe ".normalize" do
    it "passes through canonical symbols" do
      expect(described_class.normalize(:error)).to eq(:error)
      expect(described_class.normalize(:warning)).to eq(:warning)
    end

    it "translates string synonyms" do
      expect(described_class.normalize("error")).to eq(:error)
      expect(described_class.normalize("WARN")).to eq(:warning)
    end

    it "returns :unknown for unrecognized values" do
      expect(described_class.normalize(:bogus)).to eq(:unknown)
    end
  end

  describe ".failing?" do
    it "returns true for :error" do
      expect(described_class.failing?(:error)).to be(true)
    end

    it "returns false for :warning and :info" do
      expect(described_class.failing?(:warning)).to be(false)
      expect(described_class.failing?(:info)).to be(false)
    end
  end
end

RSpec.describe Dcc::Validate::Issue do
  describe ".build" do
    it "constructs an Issue with normalized severity" do
      issue = described_class.build(severity: "error", message: "boom")
      expect(issue.severity).to eq(:error)
      expect(issue.message).to eq("boom")
      expect(issue.failing?).to be(true)
    end
  end

  describe "#to_s" do
    it "includes severity, message, and location" do
      issue = described_class.build(
        severity: :error, message: "bad value", code: "test.x",
        line: 42, path: "/dcc:foo", source: "test",
      )
      expect(issue.to_s).to include("ERROR")
      expect(issue.to_s).to include("bad value")
      expect(issue.to_s).to include("line 42")
      expect(issue.to_s).to include("/dcc:foo")
    end
  end
end

RSpec.describe Dcc::Validate::Result do
  let(:issue_err) { Dcc::Validate::Issue.build(severity: :error, message: "e1") }
  let(:issue_warn) { Dcc::Validate::Issue.build(severity: :warning, message: "w1") }
  let(:issue_info) { Dcc::Validate::Issue.build(severity: :info, message: "i1") }

  subject(:result) do
    described_class.new(issues: [issue_err, issue_warn, issue_info], schema_version: "3.3.0", source: "xsd")
  end

  describe "#ok?" do
    it "returns false when there are errors" do
      expect(result.ok?).to be(false)
    end

    it "returns true when only warnings/info" do
      clean = described_class.new(issues: [issue_warn, issue_info])
      expect(clean.ok?).to be(true)
    end
  end

  describe "#errors / #warnings / #infos" do
    it "partitions issues by severity" do
      expect(result.errors).to eq([issue_err])
      expect(result.warnings).to eq([issue_warn])
      expect(result.infos).to eq([issue_info])
    end
  end

  describe "#merge" do
    it "combines issues from two results" do
      other = described_class.new(issues: [issue_warn])
      merged = result.merge(other)
      expect(merged.issues.size).to eq(4)
    end
  end

  describe "#to_json" do
    it "produces valid JSON with counts" do
      require "json"
      payload = JSON.parse(result.to_json)
      expect(payload["ok"]).to be(false)
      expect(payload["error_count"]).to eq(1)
      expect(payload["warning_count"]).to eq(1)
      expect(payload["info_count"]).to eq(1)
      expect(payload["issues"].size).to eq(3)
    end
  end

  describe "#to_s" do
    it "summarizes counts and lists errors" do
      expect(result.to_s).to include("1 error(s)")
      expect(result.to_s).to include("e1")
    end

    it "reports OK when clean" do
      clean = described_class.new(issues: [], schema_version: "3.3.0")
      expect(clean.to_s).to include("OK")
    end
  end
end
