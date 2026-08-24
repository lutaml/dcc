# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::QuantityFormat::Formatter do
  describe "#to_short" do
    it "renders compact notation with uncertainty" do
      f = described_class.new(value: BigDecimal("42.00"),
                              uncertainty: BigDecimal("0.05"), unit: "\\kelvin")
      out = f.to_short
      expect(out).to match(/42\.\d+\(\d+\)/)
      expect(out).to include("kelvin")
    end

    it "renders value only when no uncertainty" do
      f = described_class.new(value: BigDecimal(42), unit: "\\meter")
      expect(f.to_short).to include("42")
    end
  end

  describe "#to_long" do
    it "renders with ±" do
      f = described_class.new(value: BigDecimal(10),
                              uncertainty: BigDecimal("0.1"))
      expect(f.to_long).to include("±")
    end
  end

  describe "#to_latex" do
    it "renders siunitx notation" do
      f = described_class.new(value: BigDecimal("42.0"),
                              uncertainty: BigDecimal("0.5"), unit: "\\kelvin")
      expect(f.to_latex).to include("\\qty{")
      expect(f.to_latex).to include("\\kelvin")
    end
  end

  # D-SI writes `NaN` for a not-measured uncertainty, and a parsed decimal list
  # now carries it through. The precision of a rendered value is derived from
  # `log10(uncertainty)`, which has no answer for NaN, so each form says NaN
  # rather than raising.
  describe "a NaN uncertainty" do
    let(:formatter) do
      described_class.new(value: BigDecimal("42.0"),
                          uncertainty: BigDecimal("NaN"), unit: "\\kelvin")
    end

    it "renders the short form without raising" do
      expect(formatter.to_short).to eq("42.0(NaN) kelvin")
    end

    it "renders the long form without raising" do
      expect(formatter.to_long).to eq("42.0 ± NaN kelvin")
    end

    it "renders the LaTeX form without raising" do
      expect(formatter.to_latex).to eq("\\qty{42.0 +- NaN}{\\kelvin}")
    end

    # A NaN uncertainty carries no precision, so the value falls back to the
    # same two-decimal default an absent uncertainty gets. Without this the
    # two render the same number to different widths.
    it "rounds the value the way an absent uncertainty does" do
      value = BigDecimal("42.123456789")
      with_nan = described_class.new(value: value,
                                     uncertainty: BigDecimal("NaN"))
      without = described_class.new(value: value, uncertainty: nil)
      expect(with_nan.to_long).to eq("#{without.to_long} ± NaN")
    end
  end
end
