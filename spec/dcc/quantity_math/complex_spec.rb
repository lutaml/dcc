# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::QuantityMath::Complex do
  def real(value, uncertainty, unit: "\\ohm")
    Dcc::QuantityMath::Real.new(value: BigDecimal(value), unit: unit,
                                uncertainty: BigDecimal(uncertainty))
  end

  def exact(value, unit: "\\ohm")
    Dcc::QuantityMath::Real.new(value: BigDecimal(value), unit: unit)
  end

  # z1/z2/z3 are the canonical operand names from the complex propagation
  # derivation, and every comment below refers to them that way.
  # rubocop:disable RSpec/IndexedLet

  # z1 = (3 +/- 0.1) + (4 +/- 0.2)i ohm
  let(:z1) do
    described_class.cartesian(real: real("3", "0.1"), imag: real("4", "0.2"))
  end
  # z2 = (1 +/- 0.01) + (2 +/- 0.02)i ohm
  let(:z2) do
    described_class.cartesian(real: real("1", "0.01"), imag: real("2", "0.02"))
  end
  # An independent quantity with the same distribution as z1. Covariances only
  # add for independent operands, so the "u * sqrt(2)" check uses this rather
  # than `z1 + z1`.
  let(:z1_twin) do
    described_class.cartesian(real: real("3", "0.1"), imag: real("4", "0.2"))
  end
  # Exact, no uncertainty.
  let(:z3) do
    described_class.cartesian(real: exact("1"), imag: exact("1"))
  end
  # rubocop:enable RSpec/IndexedLet

  def root_two
    BigDecimal(2).sqrt(30)
  end

  def pure_imaginary
    described_class.cartesian(real: exact("0"), imag: exact("2"))
  end

  describe ".cartesian" do
    it "builds a diagonal covariance from the component uncertainties" do
      expect(z1.covariance).to eq([[BigDecimal("0.01"), BigDecimal(0)],
                                   [BigDecimal(0), BigDecimal("0.04")]])
    end

    it "treats a component with no uncertainty as exact" do
      expect(z3.covariance).to eq([[BigDecimal(0), BigDecimal(0)],
                                   [BigDecimal(0), BigDecimal(0)]])
    end

    it "raises when the real and imaginary parts carry different units" do
      expect do
        described_class.cartesian(real: real("3", "0.1"),
                                  imag: real("4", "0.2", unit: "\\henry"))
      end.to raise_error(ArgumentError, /unit mismatch/)
    end

    it "accepts an explicit covariance matrix" do
      z = described_class.cartesian(real: real("3", "0.1"),
                                    imag: real("4", "0.2"),
                                    covariance: [[1, "0.5"], ["0.5", 1]])
      expect(z.covariance[0][1]).to eq(BigDecimal("0.5"))
    end
  end

  describe ".new" do
    it "raises unless the matrix has exactly two elements" do
      matrix = Dcc::QuantityMath::Matrix.new(values: [1], units: ["\\ohm"],
                                             covariance: [[1]])
      expect { described_class.new(matrix: matrix) }
        .to raise_error(ArgumentError, /2 elements/)
    end
  end

  describe "#+" do
    it "adds components", :aggregate_failures do
      sum = z1 + z2
      expect(sum.real.value).to eq(BigDecimal(4))
      expect(sum.imag.value).to eq(BigDecimal(6))
      expect(sum.unit).to eq("\\ohm")
    end

    it "gives u * sqrt(2) on each component when added to its twin",
       :aggregate_failures do
      doubled = z1 + z1_twin
      expect(doubled.real.uncertainty.round(20))
        .to eq((BigDecimal("0.1") * root_two).round(20))
      expect(doubled.imag.uncertainty.round(20))
        .to eq((BigDecimal("0.2") * root_two).round(20))
    end

    it "raises on unit mismatch" do
      other = described_class.cartesian(
        real: real("1", "0.01", unit: "\\henry"),
        imag: real("2", "0.02", unit: "\\henry"),
      )
      expect { z1 + other }.to raise_error(ArgumentError, /unit mismatch/)
    end
  end

  describe "#-" do
    it "subtracts components", :aggregate_failures do
      diff = z1 - z2
      expect(diff.real.value).to eq(BigDecimal(2))
      expect(diff.imag.value).to eq(BigDecimal(2))
    end
  end

  describe "#*" do
    it "multiplies in Cartesian form", :aggregate_failures do
      # (3 + 4i)(1 + 2i) = (3 - 8) + (6 + 4)i = -5 + 10i
      product = z1 * z2
      expect(product.real.value).to eq(BigDecimal("-5"))
      expect(product.imag.value).to eq(BigDecimal(10))
      expect(product.unit).to eq("\\ohm\\cdot\\ohm")
    end

    it "propagates the full 2x2 covariance, off-diagonal included" do
      expect((z1 * z2).covariance)
        .to eq([[BigDecimal("0.1773"), BigDecimal("-0.0636")],
                [BigDecimal("-0.0636"), BigDecimal("0.0852")]])
    end
  end

  describe "#/" do
    it "divides in Cartesian form", :aggregate_failures do
      # (3 + 4i)/(1 + 2i) = (3 + 4i)(1 - 2i)/5 = (11 - 2i)/5 = 2.2 - 0.4i
      ratio = z1 / z2
      expect(ratio.real.value).to eq(BigDecimal("2.2"))
      expect(ratio.imag.value).to eq(BigDecimal("-0.4"))
      expect(ratio.unit).to eq("\\ohm\\cdot\\ohm^-1")
    end

    it "propagates the full 2x2 covariance" do
      expect((z1 / z2).covariance)
        .to eq([[BigDecimal("0.00717648"), BigDecimal("0.00248064")],
                [BigDecimal("0.00248064"), BigDecimal("0.00332352")]])
    end

    it "bounds the digits a non-terminating derivative adds",
       :aggregate_failures do
      # Ruby's Complex#/ runs Smith's algorithm, whose internal 1/3 does not
      # terminate, so an unbounded 1/z2 would carry ~130 digits of noise into
      # the covariance. Bounded, the derivative rounds back to the exact
      # 0.1 - 0.3i and var(Re) comes out exactly 0.1^2*0.01 + 0.3^2*0.04.
      ratio = z1 / described_class.cartesian(real: exact("1"),
                                             imag: exact("3"))
      expect(ratio.covariance[0][0]).to eq(BigDecimal("0.0037"))
      expect(ratio.covariance.flatten.map(&:precision).max)
        .to be <= described_class::DERIVATIVE_PRECISION
    end

    it "raises rather than producing NaN when the divisor is zero" do
      zero = described_class.cartesian(real: exact("0"), imag: exact("0"))
      expect { z1 / zero }.to raise_error(ZeroDivisionError)
    end

    it "raises when the divisor is zero but carries uncertainty" do
      zero = described_class.cartesian(real: real("0", "0.1"),
                                       imag: real("0", "0.1"))
      expect { z1 / zero }.to raise_error(ZeroDivisionError)
    end

    it "divides by a purely imaginary quantity", :aggregate_failures do
      # (3 + 4i)/2i = (3 + 4i) * -0.5i = 2 - 1.5i.
      ratio = z1 / pure_imaginary
      expect(ratio.real.value).to eq(BigDecimal(2))
      expect(ratio.imag.value).to eq(BigDecimal("-1.5"))
    end

    it "propagates through a purely imaginary divisor" do
      # The divisor is exact, so only z1's variances propagate: J's real row
      # is [0, 0.5] and its imaginary row [-0.5, 0].
      expect((z1 / pure_imaginary).covariance)
        .to eq([[BigDecimal("0.01"), BigDecimal(0)],
                [BigDecimal(0), BigDecimal("0.0025")]])
    end
  end

  describe "chained operations" do
    it "carries the real/imaginary covariance into the next operation",
       :aggregate_failures do
      # cov(Re, Im) of z1 * z2 is -0.0636. Feeding the full matrix forward
      # gives var(Re) = 0.3897 for (z1 * z2) * z3; a diagonal-only model
      # would give 0.2625, understating it by a third.
      chained = (z1 * z2) * z3
      expect(chained.real.value).to eq(BigDecimal("-15"))
      expect(chained.imag.value).to eq(BigDecimal(5))
      expect(chained.covariance[0][0]).to eq(BigDecimal("0.3897"))
    end
  end

  describe "under a reduced global BigDecimal.limit" do
    # Long decimals, so rounding at 6 digits is visible. These are methods
    # rather than `let`s on purpose: the helper below calls its block twice
    # and a memoized value would be built once, at full precision.
    def wide
      described_class.cartesian(real: real("3.111111111", "0.123456789"),
                                imag: real("4.222222222", "0.234567891"))
    end

    def other
      described_class.cartesian(real: real("1.333333333", "0.011111111"),
                                imag: real("2.444444444", "0.022222222"))
    end

    def third
      described_class.cartesian(real: exact("1.777777777"),
                                imag: exact("1.555555555"))
    end

    # Compares the whole covariance against the same computation at full
    # precision. Asserting symmetry alone would pass a wrong-but-symmetric
    # result.
    def expect_matching_covariance
      reference = yield.covariance
      previous = BigDecimal.limit(6)
      begin
        expect(yield.covariance).to eq(reference)
      ensure
        BigDecimal.limit(previous)
      end
    end

    it "builds the default diagonal covariance at full precision" do
      expect_matching_covariance { wide }
    end

    it "divides at full precision" do
      expect_matching_covariance { wide / other }
    end

    it "chains at full precision" do
      # Only a chained operation can round the off-diagonal: the first
      # product supplies it, and a full C is what makes J C J^T asymmetric.
      # Two diagonal operands cannot.
      expect_matching_covariance { (wide * other) * third }
    end
  end

  describe "#uncertain?" do
    it "is true when only the real part carries uncertainty" do
      half = described_class.cartesian(real: real("3", "0.1"), imag: exact("4"))
      expect(half.uncertain?).to be(true)
    end

    it "is false for an exact quantity" do
      expect(z3.uncertain?).to be(false)
    end
  end

  describe "#to_c" do
    it "returns a Ruby Complex of BigDecimals" do
      expect(z1.to_c)
        .to eq(Complex.rectangular(BigDecimal(3), BigDecimal(4)))
    end
  end

  describe "#to_s" do
    it "shows both components and names the shared unit once",
       :aggregate_failures do
      expect(z1.to_s).to include("0.1")
      expect(z1.to_s).to include("0.2")
      expect(z1.to_s.scan("\\ohm").size).to eq(1)
    end

    it "subtracts a negative imaginary part instead of adding it",
       :aggregate_failures do
      negative = described_class.cartesian(real: real("3", "0.1"),
                                           imag: real("-1.5", "0.2"))
      expect(negative.to_s).to include("- (0.15e1")
      expect(negative.to_s).not_to include("+ (-")
    end
  end
end
