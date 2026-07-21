# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::QuantityFormat::Formatter do
  describe "#to_short" do
    it "renders compact notation with uncertainty" do
      f = described_class.new(value: BigDecimal("42.00"), uncertainty: BigDecimal("0.05"), unit: "\\kelvin")
      out = f.to_short
      expect(out).to match(/42\.\d+\(\d+\)/)
      expect(out).to include("kelvin")
    end

    it "renders value only when no uncertainty" do
      f = described_class.new(value: BigDecimal("42"), unit: "\\meter")
      expect(f.to_short).to include("42")
    end
  end

  describe "#to_long" do
    it "renders with ±" do
      f = described_class.new(value: BigDecimal("10"), uncertainty: BigDecimal("0.1"))
      expect(f.to_long).to include("±")
    end
  end

  describe "#to_latex" do
    it "renders siunitx notation" do
      f = described_class.new(value: BigDecimal("42.0"), uncertainty: BigDecimal("0.5"), unit: "\\kelvin")
      expect(f.to_latex).to include("\\qty{")
      expect(f.to_latex).to include("\\kelvin")
    end
  end
end