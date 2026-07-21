# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::QuantityMath::Real do
  let(:ten_k)    { described_class.new(value: BigDecimal("10"), unit: "\\kelvin", uncertainty: BigDecimal("0.1")) }
  let(:twenty_k) { described_class.new(value: BigDecimal("20"), unit: "\\kelvin", uncertainty: BigDecimal("0.2")) }

  describe "#+" do
    it "adds values and propagates uncertainty via RSS" do
      sum = ten_k + twenty_k
      expect(sum.value).to eq(BigDecimal("30"))
      expected_unc = BigDecimal(Math.sqrt((0.1 ** 2) + (0.2 ** 2)).to_s)
        .round(10)
      expect(sum.uncertainty.round(10)).to eq(expected_unc)
    end

    it "raises on unit mismatch" do
      other = described_class.new(value: 5, unit: "\\meter", uncertainty: 0.1)
      expect { ten_k + other }.to raise_error(ArgumentError, /unit mismatch/)
    end
  end

  describe "#-" do
    it "subtracts values and propagates via RSS" do
      diff = twenty_k - ten_k
      expect(diff.value).to eq(BigDecimal("10"))
      expect(diff.uncertainty).to be_a(BigDecimal)
    end
  end

  describe "#*" do
    it "multiplies values with fractional uncertainty" do
      product = ten_k * twenty_k
      expect(product.value).to eq(BigDecimal("200"))
      expect(product.uncertainty).to be_a(BigDecimal)
    end
  end

  describe "#/" do
    it "divides values with fractional uncertainty" do
      ratio = twenty_k / ten_k
      expect(ratio.value).to eq(BigDecimal("2"))
      expect(ratio.uncertainty).to be_a(BigDecimal)
    end
  end

  describe "#**" do
    it "raises to power with derivative-based uncertainty" do
      square = ten_k ** 2
      expect(square.value).to eq(BigDecimal("100"))
      expect(square.uncertainty).to eq(BigDecimal("2")) # |2 * 10 * 0.1| = 2
    end
  end

  describe "#to_s" do
    it "includes value, uncertainty, and unit" do
      expect(ten_k.to_s).to include("0.1")
      expect(ten_k.to_s).to include("\\kelvin")
    end
  end
end