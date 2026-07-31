# frozen_string_literal: true

RSpec.describe Dcc::Extract::Formula do
  let(:fixture) { File.read(fixtures_path("dcclib", "valid_formula.xml")) }
  let(:dcc) { Dcc.parse(fixture) }
  let(:formulae) { described_class.call(dcc) }
  let(:formula) { formulae.first }

  # Reference values from PTB dcclib:
  # spec/fixtures/dcclib_python_tests/tests/extraction/formulae/
  #   test_formulae.py
  # These are exact BigDecimal results, verified — do not round.
  let(:defaults) do
    [
      "100.0225", "109.77301212171875", "119.442643549375",
      "129.03139428296875", "138.5392643225"
    ].map { |value| BigDecimal(value) }
  end

  describe "the Callendar-Van-Dusen fixture" do
    it "finds exactly one formula" do
      expect(formulae.size).to eq(1)
    end

    it "reads the function name" do
      expect(formula.name).to eq("R")
    end

    it "reads the bound variable" do
      expect(formula.bound_variables).to eq(["T"])
    end
  end

  describe "bindings from the sibling quantity list" do
    it "binds every identified quantity" do
      expect(formula.bindings.keys).to contain_exactly("R0", "A", "B", "T")
    end

    it "reads a scalar si:real value" do
      expect(formula.bindings["R0"].value).to eq(BigDecimal("100.0225"))
    end

    it "keeps the unit alongside the value" do
      expect(formula.bindings["R0"].unit).to include("kilogram")
    end

    it "reads a list si:realListXMLList value" do
      expect(formula.bindings["T"].value)
        .to eq([0, 25, 50, 75, 100].map { |n| BigDecimal(n) })
    end
  end

  describe "evaluation" do
    it "evaluates over the T list from the document" do
      expect(formula.evaluate).to eq(defaults)
    end

    it "evaluates at a single overridden T" do
      expect(formula.evaluate("T" => 42))
        .to eq([BigDecimal("116.357161312039")])
    end

    it "evaluates element-wise over several T values" do
      expect(formula.evaluate("T" => [42, 43]))
        .to eq([BigDecimal("116.357161312039"),
                BigDecimal("116.74329952359275")])
    end

    it "lets a parameter override replace the document value" do
      expect(formula.evaluate("T" => 42, "R0" => 1))
        .to eq([BigDecimal("1.1633098684")])
    end
  end

  it "returns nothing for a DCC without formulae" do
    plain = Dcc.parse(File.read(fixtures_path("dcclib", "valid.xml")))

    expect(described_class.call(plain)).to be_empty
  end

  # `dcc:listType` is recursive. Walking only the first level of lists
  # loses every binding nested below it — silently, since the formula
  # itself still parses.
  describe "quantities in a nested list" do
    # Anchored on the closing run of the *coefficients* result, so the
    # extra </dcc:list> lands on the list we wrapped rather than on the
    # first result's table. Plain methods, not `let`, to stay under the
    # memoized-helper limit.
    def closing
      %r{</dcc:list>\s*</dcc:data>\s*</dcc:result>\s*</dcc:results>}m
    end

    def nested_formula
      wrapped = fixture.sub(
        '<dcc:list refType="gp_table2">',
        '<dcc:list refType="outer"><dcc:list refType="gp_table2">',
      )
      nested = wrapped.sub(closing) do
        "</dcc:list></dcc:list></dcc:data></dcc:result></dcc:results>"
      end
      described_class.call(Dcc.parse(nested)).first
    end

    it "still finds every binding" do
      expect(nested_formula.bindings.keys)
        .to contain_exactly("R0", "A", "B", "T")
    end

    it "still evaluates correctly" do
      expect(nested_formula.evaluate("T" => 42))
        .to eq([BigDecimal("116.357161312039")])
    end
  end

  # `si:value` is an unvalidated :string attribute, so these are ordinary
  # real-world documents, not crafted ones. None may leak a raw
  # ArgumentError or TypeError out of a public extraction call.
  describe "malformed si:value" do
    def dcc_with_value(inner)
      Dcc.parse(fixture.sub("<si:value>100.0225</si:value>", inner))
    end

    it "rejects a non-numeric value" do
      expect { described_class.call(dcc_with_value("<si:value>x</si:value>")) }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    it "rejects a missing value" do
      expect { described_class.call(dcc_with_value("")) }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    it "rejects a non-finite value" do
      infinite = "<si:value>Infinity</si:value>"

      expect { described_class.call(dcc_with_value(infinite)) }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end
  end

  # The invariant the whole guard rests on: a Quantity cannot exist holding
  # a bad number, which is why Evaluator#quantify may trust its contents.
  describe Dcc::Extract::Formula::Quantity do
    def build(value)
      described_class.new(value: value, unit: nil, uncertainty: nil)
    end

    it "coerces a scalar string on construction" do
      expect(build("100.0225").value).to eq(BigDecimal("100.0225"))
    end

    it "coerces every element of a list" do
      expect(build(["1", 2]).values).to eq([BigDecimal(1), BigDecimal(2)])
    end

    it "refuses a non-numeric value" do
      expect { build("banana") }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    # Ruby reads this as 1000. No document writes a number that way, so
    # taking it silently would inflate the value tenfold.
    it "refuses underscore-separated digits" do
      expect { build("1_000") }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    it "refuses a nil value" do
      expect { build(nil) }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end

    it "refuses a non-finite value" do
      expect { build("Infinity") }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end

    it "refuses a non-finite element inside a list" do
      expect { build(["1", "NaN"]) }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end

    # `respond_to?(:to_ary)` alone would reach a NoMethodError on `map`.
    it "refuses an object whose to_ary breaks the protocol" do
      broken = Class.new { def to_ary = "not an array" }.new

      expect { build(broken) }
        .to raise_error(Dcc::ExtractionError, /not a usable list/i)
    end

    # Data freezes the struct, not the array inside it.
    it "freezes the coerced list" do
      expect(build(%w[1 2]).value).to be_frozen
    end

    it "cannot be mutated past the constructor" do
      expect { build(%w[1 2]).value << BigDecimal(3) }
        .to raise_error(FrozenError)
    end
  end

  # `Formula.call` returns AST nodes as public API, so callers build them.
  describe Dcc::Extract::Formula::Ast::Number do
    it "coerces its value" do
      expect(described_class.new(value: "2").value).to eq(BigDecimal(2))
    end

    it "refuses a non-finite value" do
      expect { described_class.new(value: BigDecimal("Infinity")) }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end
  end

  describe Dcc::Extract::Formula::Ast::Constant do
    it "accepts a name the evaluator dispatches on" do
      expect(described_class.new(name: :pi).name).to eq(:pi)
    end

    # Without the guard the evaluator's `case` returns nil and the formula
    # evaluates to [nil] — a wrong answer rather than an error.
    it "refuses a name outside the canonical set" do
      expect { described_class.new(name: :bogus) }
        .to raise_error(Dcc::ExtractionError, /not a formula constant/i)
    end
  end

  describe Dcc::Extract::Formula::Ast::Apply do
    # Without the guard `trigonometric` returns nil and `finite` raises
    # NoMethodError, leaking a raw Ruby failure out of the public API.
    it "refuses an operator outside the canonical set" do
      operand = Dcc::Extract::Formula::Ast::Number.new(value: 2)
      expect { described_class.new(operator: :bogus, operands: [operand]) }
        .to raise_error(Dcc::ExtractionError, /not a formula operator/i)
    end
  end

  # The two sets are declared on Ast to keep Parser a one-way dependency.
  # This is what stops them drifting apart.
  describe "the canonical sets" do
    it "covers every operator the parser emits" do
      expect(Dcc::Extract::Formula::Ast::OPERATORS)
        .to match_array(Dcc::Extract::Formula::Parser::OPERATORS.values)
    end

    it "covers every constant the parser emits" do
      expect(Dcc::Extract::Formula::Ast::CONSTANTS)
        .to match_array(Dcc::Extract::Formula::Parser::CONSTANTS.values)
    end
  end
end
