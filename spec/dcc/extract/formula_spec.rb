# frozen_string_literal: true

require "spec_helper"
require "bigdecimal"

RSpec.describe Dcc::Extract::Formula do
  before { Dcc.load_all! }

  describe ".call" do
    let(:dcc) { Dcc.parse(File.read(fixtures_path("dcclib", "valid_formula.xml"))) }

    it "returns an Array of parsed ASTs (may be empty if formulas are nested)" do
      asts = described_class.call(dcc)
      expect(asts).to be_an(Array)
    end
  end
end

RSpec.describe Dcc::Extract::Formula::Parser do
  it "parses a simple apply" do
    mathml = <<~XML
      <math xmlns="http://www.w3.org/1998/Math/MathML">
        <apply><plus/><cn>1</cn><cn>2</cn></apply>
      </math>
    XML
    ast = described_class.parse(mathml)
    expect(ast.evaluate({})).to eq(BigDecimal("3"))
  end

  it "parses variables" do
    mathml = <<~XML
      <math xmlns="http://www.w3.org/1998/Math/MathML">
        <apply><times/><ci>x</ci><cn>2</cn></apply>
      </math>
    XML
    ast = described_class.parse(mathml)
    expect(ast.evaluate(x: BigDecimal("3"))).to eq(BigDecimal("6"))
  end

  it "parses nested applies" do
    mathml = <<~XML
      <math xmlns="http://www.w3.org/1998/Math/MathML">
        <apply>
          <plus/>
          <cn>1</cn>
          <apply><times/><cn>2</cn><cn>3</cn></apply>
        </apply>
      </math>
    XML
    ast = described_class.parse(mathml)
    expect(ast.evaluate({})).to eq(BigDecimal("7"))
  end
end

RSpec.describe Dcc::Extract::Formula::Evaluator do
  it "handles basic operators" do
    expect(described_class.apply(:plus, [BigDecimal("1"), BigDecimal("2")])).to eq(BigDecimal("3"))
    expect(described_class.apply(:minus, [BigDecimal("5"), BigDecimal("2")])).to eq(BigDecimal("3"))
    expect(described_class.apply(:times, [BigDecimal("3"), BigDecimal("4")])).to eq(BigDecimal("12"))
    expect(described_class.apply(:divide, [BigDecimal("12"), BigDecimal("4")])).to eq(BigDecimal("3"))
  end

  it "handles sqrt" do
    result = described_class.apply(:sqrt, [BigDecimal("16")])
    expect(result.to_i).to eq(4)
  end

  it "raises on unknown operator" do
    expect { described_class.apply(:unknown_op, [BigDecimal("1")]) }
      .to raise_error(::Dcc::ExtractionError, /unsupported MathML operator/)
  end
end