# frozen_string_literal: true

require "spec_helper"

RSpec.describe Dcc::Validate::BusinessRules do
  before { Dcc.load_all! }

  describe ".call" do
    it "passes for a valid document" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))
      result = described_class.call(dcc)
      expect(result.source).to eq("business_rule")
    end

    it "fails when uniqueIdentifier is empty" do
      dcc = Dcc.parse(File.read(fixtures_path("dcclib", "invalid_schema.xml")))
      result = described_class.call(dcc)
      unique_issues = result.errors.select { |i| i.message.include?("uniqueIdentifier") }
      expect(unique_issues).not_to be_empty
    end
  end

  describe "Registry" do
    it "supports adding rules (OCP)" do
      count_before = described_class::Registry.all.size
      test_rule = Class.new(described_class::Rule) do
        def check_on(_dcc)
          [issue(severity: :info, message: "test")]
        end
      end
      described_class::Registry.add(test_rule)
      expect(described_class::Registry.all.size).to eq(count_before + 1)
    ensure
      described_class::Registry.reset!
      load File.expand_path("lib/dcc/validate/business_rules.rb", Dir.pwd)
    end
  end
end