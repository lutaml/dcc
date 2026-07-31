# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::QuantityMath::Matrix do
  # x = (3, 4) with variances 4 and 9 and covariance 1 between them.
  subject(:pair) do
    described_class.new(values: [3, 4],
                        units: ["\\kelvin", "\\kelvin"],
                        covariance: [[4, 1], [1, 9]])
  end

  # Independent quantity with the same distribution as `pair`. Covariances
  # only add for independent operands, so the sum specs use this rather than
  # adding `pair` to itself.
  let(:twin) do
    described_class.new(values: [3, 4],
                        units: ["\\kelvin", "\\kelvin"],
                        covariance: [[4, 1], [1, 9]])
  end

  # Long decimals, so a reduced BigDecimal.limit visibly rounds the product.
  let(:wide) do
    described_class.new(values: [1, 2], units: [nil, nil],
                        covariance: [["4.123456789", "1.987654321"],
                                     ["1.987654321", "9.135792468"]])
  end

  let(:wide_propagation) do
    { values: [1, 2], units: [nil, nil],
      jacobian: [["1.111111111", "2.222222222"],
                 ["3.333333333", "0.777777777"]] }
  end

  # Runs the block at a reduced global precision, always restoring what the
  # caller had, so one example cannot poison the rest of the suite.
  def with_limit(digits)
    previous = BigDecimal.limit(digits)
    yield
  ensure
    BigDecimal.limit(previous)
  end

  # Builds a matrix, then mutates every array the caller handed in.
  def matrix_from_mutated_inputs
    values = [1, 2]
    units = [nil, nil]
    covariance = [[1, 0], [0, 1]]
    matrix = described_class.new(values: values, units: units,
                                 covariance: covariance)
    values << 3
    units << "\\kelvin"
    covariance[0][0] = -5
    matrix
  end

  # Builds a matrix, then mutates the unit string the caller handed in.
  def matrix_from_mutated_unit
    unit = +"\\kelvin"
    matrix = described_class.new(values: [1], units: [unit],
                                 covariance: [[1]])
    unit << "-mutated"
    matrix
  end

  describe ".new" do
    it "casts values and covariance entries to BigDecimal",
       :aggregate_failures do
      expect(pair.values).to all(be_a(BigDecimal))
      expect(pair.covariance.flatten).to all(be_a(BigDecimal))
    end

    it "raises when the covariance has too few rows for the values" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[1, 0]])
      end.to raise_error(ArgumentError, /dimension mismatch/)
    end

    it "raises when the covariance matrix is not square" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[1, 0, 0], [0, 1, 0]])
      end.to raise_error(ArgumentError, /dimension mismatch/)
    end

    it "raises when the unit vector length does not match the values" do
      expect do
        described_class.new(values: [1, 2], units: [nil],
                            covariance: [[1, 0], [0, 1]])
      end.to raise_error(ArgumentError, /dimension mismatch/)
    end

    it "raises on a non-finite covariance entry" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[BigDecimal::INFINITY, 0], [0, 1]])
      end.to raise_error(ArgumentError, /not finite/)
    end

    it "raises on an asymmetric covariance matrix" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[1, 2], [3, 4]])
      end.to raise_error(ArgumentError, /not symmetric/)
    end

    it "raises on a negative variance" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[-1, 0], [0, 1]])
      end.to raise_error(ArgumentError, /negative variance/)
    end

    it "raises on a symmetric matrix that is not positive semi-definite" do
      # Passes the finite, symmetric and non-negative-diagonal checks, but
      # propagates to a negative variance under J = [[1, -1]].
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[0, 1], [1, 1]])
      end.to raise_error(ArgumentError, /positive semi-definite/)
    end

    it "accepts a singular but positive semi-definite covariance matrix" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[1, 1], [1, 1]])
      end.not_to raise_error
    end

    it "accepts a zero pivot when the rest of its column is zero" do
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[0, 0], [0, 1]])
      end.not_to raise_error
    end

    it "rejects a matrix whose second pivot goes negative" do
      # LDL^T reduces [[1, 2], [2, 1]] to a second pivot of -3.
      expect do
        described_class.new(values: [1, 2], units: [nil, nil],
                            covariance: [[1, 2], [2, 1]])
      end.to raise_error(ArgumentError, /positive semi-definite/)
    end

    it "accepts Rational entries", :aggregate_failures do
      matrix = described_class.new(values: [Rational(1, 3)], units: [nil],
                                   covariance: [[Rational(1, 4)]])
      expect(matrix.values.first.round(10)).to eq(BigDecimal("0.3333333333"))
      expect(matrix.uncertainties.first).to eq(BigDecimal("0.5"))
    end

    it "normalises a negative zero variance", :aggregate_failures do
      # -0 slips past the negative? check but keeps its sign through sqrt,
      # printing an uncertainty of -0.0.
      matrix = described_class.new(values: [1], units: [nil],
                                   covariance: [[BigDecimal("-0")]])
      expect(matrix.uncertainties.first.sign).to be_positive
      expect(matrix.to_s).not_to include("-0.0")
    end

    it "does not alias the caller's arrays", :aggregate_failures do
      matrix = matrix_from_mutated_inputs
      expect(matrix.values.size).to eq(2)
      expect(matrix.units.size).to eq(2)
      expect(matrix.covariance[0][0]).to eq(BigDecimal(1))
    end

    it "freezes what it exposes", :aggregate_failures do
      expect(pair.values).to be_frozen
      expect(pair.units).to be_frozen
      expect(pair.covariance).to be_frozen
      expect(pair.covariance.first).to be_frozen
    end

    it "copies the caller's unit strings rather than holding them",
       :aggregate_failures do
      matrix = matrix_from_mutated_unit
      expect(matrix.units.first).to eq("\\kelvin")
      expect(matrix[0].unit).to eq("\\kelvin")
    end

    it "freezes the unit strings it hands out", :aggregate_failures do
      expect(pair.units.first).to be_frozen
      expect(pair[0].unit).to be_frozen
      expect { pair.units.first << "x" }.to raise_error(FrozenError)
    end
  end

  describe "#uncertainties" do
    it "returns the square root of each diagonal entry" do
      expect(pair.uncertainties.map { |u| u.round(10) })
        .to eq([BigDecimal(2), BigDecimal(3)])
    end
  end

  describe "#[]" do
    it "raises on an out-of-range index" do
      expect { pair[2] }.to raise_error(IndexError, /out of range/)
    end

    it "raises on a negative index rather than wrapping" do
      expect { pair[-1] }.to raise_error(IndexError, /out of range/)
    end

    it "returns the element as a univariate Real", :aggregate_failures do
      element = pair[1]
      expect(element).to be_a(Dcc::QuantityMath::Real)
      expect(element.value).to eq(BigDecimal(4))
      expect(element.unit).to eq("\\kelvin")
      expect(element.uncertainty.round(10)).to eq(BigDecimal(3))
    end
  end

  describe "#+" do
    it "adds values element-wise and sums the covariance matrices",
       :aggregate_failures do
      sum = pair + twin
      expect(sum.values).to eq([BigDecimal(6), BigDecimal(8)])
      expect(sum.covariance).to eq([[BigDecimal(8), BigDecimal(2)],
                                    [BigDecimal(2), BigDecimal(18)]])
    end

    it "gives u * sqrt(2) per element when added to its twin" do
      root_two = BigDecimal(2).sqrt(30)
      expect((pair + twin).uncertainties.map { |u| u.round(10) })
        .to eq([(BigDecimal(2) * root_two).round(10),
                (BigDecimal(3) * root_two).round(10)])
    end

    it "raises on unit mismatch" do
      other = described_class.new(values: [1, 1],
                                  units: ["\\pascal", "\\kelvin"],
                                  covariance: [[1, 0], [0, 1]])
      expect { pair + other }.to raise_error(ArgumentError, /unit mismatch/)
    end
  end

  describe "#-" do
    it "subtracts values element-wise but still sums the covariances",
       :aggregate_failures do
      diff = pair - twin
      expect(diff.values).to eq([BigDecimal(0), BigDecimal(0)])
      expect(diff.covariance.first.first).to eq(BigDecimal(8))
    end
  end

  describe "#propagate" do
    it "applies J C J^T, so correlation between elements is carried through",
       :aggregate_failures do
      # y = x1 + x2, J = [[1, 1]].
      # C_y = 4 + 1 + 1 + 9 = 15. Ignoring the off-diagonal would give 13.
      total = pair.propagate(values: [7], units: ["\\kelvin"],
                             jacobian: [[1, 1]])
      expect(total.covariance).to eq([[BigDecimal(15)]])
      expect(total.uncertainties.first.round(20))
        .to eq(BigDecimal(15).sqrt(30).round(20))
    end

    it "scales a single element" do
      scaled = pair.propagate(values: [6], units: ["\\kelvin"],
                              jacobian: [[2, 0]])
      expect(scaled.covariance).to eq([[BigDecimal(16)]])
    end

    it "raises when the Jacobian has too few rows for the output values" do
      expect do
        pair.propagate(values: [1, 2], units: [nil, nil], jacobian: [[1, 1]])
      end.to raise_error(ArgumentError, /jacobian shape mismatch/)
    end

    it "raises when a Jacobian row is too short for the input dimension" do
      expect do
        pair.propagate(values: [1], units: [nil], jacobian: [[1]])
      end.to raise_error(ArgumentError, /jacobian shape mismatch/)
    end

    it "raises on a ragged Jacobian" do
      expect do
        pair.propagate(values: [1, 2], units: [nil, nil],
                       jacobian: [[1, 1], [1]])
      end.to raise_error(ArgumentError, /jacobian shape mismatch/)
    end

    it "matches the unlimited-precision result under a reduced limit" do
      # Rounded to 6 digits, J C J^T is neither symmetric nor equal to the
      # true product. Asserting symmetry alone would let a wrong-but-
      # symmetric covariance pass, so compare the whole matrix.
      reference = wide.propagate(**wide_propagation)
      with_limit(6) do
        expect(wide.propagate(**wide_propagation).covariance)
          .to eq(reference.covariance)
      end
    end

    it "restores the caller's BigDecimal.limit" do
      with_limit(6) do
        pair.propagate(values: [7], units: ["\\kelvin"], jacobian: [[1, 1]])
        expect(BigDecimal.limit).to eq(6)
      end
    end
  end

  describe "Dcc::QuantityMath.exact_covariance" do
    it "restores the caller's BigDecimal.limit when the block raises",
       :aggregate_failures do
      with_limit(6) do
        expect { Dcc::QuantityMath.exact_covariance { raise "boom" } }
          .to raise_error("boom")
        expect(BigDecimal.limit).to eq(6)
      end
    end
  end

  describe "#to_s" do
    it "lists each element with its unit and uncertainty" do
      expect(pair.to_s).to include("\\kelvin")
    end
  end
end
