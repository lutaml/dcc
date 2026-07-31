# frozen_string_literal: true

RSpec.describe Dcc::Extract::Formula::Evaluator do
  # Helpers rather than constant assignments — a bare `Ast = ...` here
  # would leak to top level and collide with the parser spec.
  def node(kind, **fields)
    Dcc::Extract::Formula::Ast.const_get(kind).new(**fields)
  end

  def ast(body, bindings: {}, bound: [])
    Dcc::Extract::Formula::Ast.new(
      name: "f", bound_variables: bound, body: body, bindings: bindings,
    )
  end

  def num(string)
    node(:Number, value: BigDecimal(string))
  end

  def var(name)
    node(:Variable, name: name)
  end

  def apply(operator, *operands)
    node(:Apply, operator: operator, operands: operands)
  end

  def quantity(value)
    Dcc::Extract::Formula::Quantity.new(value: value, unit: nil,
                                        uncertainty: nil)
  end

  def evaluate(body, **options)
    described_class.call(ast(body, **options))
  end

  def result(body, **options)
    evaluate(body, **options).first
  end

  describe "arithmetic" do
    it "adds" do
      expect(evaluate(apply(:+, num("1"), num("2"), num("3"))))
        .to eq([BigDecimal(6)])
    end

    it "multiplies" do
      expect(evaluate(apply(:*, num("2"), num("3")))).to eq([BigDecimal(6)])
    end

    it "subtracts" do
      expect(evaluate(apply(:-, num("5"), num("3")))).to eq([BigDecimal(2)])
    end

    it "negates a single operand" do
      expect(evaluate(apply(:-, num("5")))).to eq([BigDecimal(-5)])
    end

    it "keeps addition and multiplication exact" do
      expect(evaluate(apply(:*, num("100.0225"), num("1.0974831875"))))
        .to eq([BigDecimal("109.77301212171875")])
    end

    it "divides exactly when the quotient terminates" do
      expect(evaluate(apply(:/, num("1"), num("8"))))
        .to eq([BigDecimal("0.125")])
    end

    it "divides a recurring quotient to 34 significant digits" do
      expect(evaluate(apply(:/, num("1"), num("3"))))
        .to eq([BigDecimal("0.3333333333333333333333333333333333")])
    end
  end

  describe "powers" do
    it "raises to non-negative integer powers exactly" do
      expect(evaluate(apply(:**, num("1.5"), num("2"))))
        .to eq([BigDecimal("2.25")])
    end

    # `**` picks its own precision: BigDecimal("3") ** -1 gives 32 threes.
    # Routing through `divide` gives the full 34.
    it "computes a negative integer power at full precision" do
      expect(evaluate(apply(:**, num("3"), num("-1"))))
        .to eq([BigDecimal("0.3333333333333333333333333333333333")])
    end

    it "keeps a terminating negative power exact" do
      expect(evaluate(apply(:**, num("2"), num("-2"))))
        .to eq([BigDecimal("0.25")])
    end

    it "raises to fractional powers" do
      expect(result(apply(:**, num("9"), num("0.5"))).round(20))
        .to eq(BigDecimal(3))
    end

    it "returns zero for a zero base with a positive fractional exponent" do
      expect(evaluate(apply(:**, num("0"), num("0.5")))).to eq([BigDecimal(0)])
    end
  end

  describe "roots" do
    it "takes a square root when no degree is given" do
      expect(result(apply(:root, num("2"))).round(20))
        .to eq(BigDecimal("1.4142135623730950488"))
    end

    it "takes an explicit square root" do
      expect(evaluate(apply(:root, num("9"), num("2")))).to eq([BigDecimal(3)])
    end

    it "takes an nth root" do
      expect(result(apply(:root, num("27"), num("3"))).round(20))
        .to eq(BigDecimal(3))
    end

    it "returns zero for a zero radicand with a positive degree" do
      expect(evaluate(apply(:root, num("0"), num("3")))).to eq([BigDecimal(0)])
    end
  end

  describe "transcendentals" do
    it "round-trips exp through ln" do
      expect(result(apply(:ln, apply(:exp, num("1")))).round(20))
        .to eq(BigDecimal(1))
    end

    it "computes exp" do
      expect(result(apply(:exp, num("1"))).round(20))
        .to eq(BigDecimal("2.71828182845904523536"))
    end

    it "computes log base ten" do
      expect(result(apply(:log, num("100"))).round(20)).to eq(BigDecimal(2))
    end

    it "computes sin" do
      expect(evaluate(apply(:sin, num("0")))).to eq([BigDecimal(0)])
    end

    it "computes cos" do
      expect(result(apply(:cos, num("0"))).round(20)).to eq(BigDecimal(1))
    end

    it "computes tan" do
      expect(evaluate(apply(:tan, num("0")))).to eq([BigDecimal(0)])
    end

    it "computes abs" do
      expect(evaluate(apply(:abs, num("-3")))).to eq([BigDecimal(3)])
    end

    it "resolves pi" do
      expect(result(node(:Constant, name: :pi)).round(10))
        .to eq(BigDecimal("3.1415926536"))
    end

    it "resolves e" do
      expect(result(node(:Constant, name: :e)).round(10))
        .to eq(BigDecimal("2.7182818285"))
    end
  end

  # BigDecimal lets some of these through as Infinity/NaN and raises raw
  # stdlib errors on others. All must surface as Dcc::ExtractionError.
  describe "numeric domain" do
    it "rejects division by zero" do
      expect { evaluate(apply(:/, num("1"), num("0"))) }
        .to raise_error(Dcc::ExtractionError, /division by zero/i)
    end

    it "rejects a zero base raised to a negative power" do
      expect { evaluate(apply(:**, num("0"), num("-1"))) }
        .to raise_error(Dcc::ExtractionError, /division by zero/i)
    end

    it "rejects a negative base raised to a fractional power" do
      expect { evaluate(apply(:**, num("-4"), num("0.5"))) }
        .to raise_error(Dcc::ExtractionError, /fractional power/i)
    end

    it "rejects a zero base raised to a negative fractional power" do
      expect { evaluate(apply(:**, num("0"), num("-0.5"))) }
        .to raise_error(Dcc::ExtractionError, /division by zero/i)
    end

    it "rejects a negative radicand" do
      expect { evaluate(apply(:root, num("-1"))) }
        .to raise_error(Dcc::ExtractionError, /negative value/i)
    end

    it "rejects a negative radicand with an odd degree" do
      expect { evaluate(apply(:root, num("-8"), num("3"))) }
        .to raise_error(Dcc::ExtractionError, /negative value/i)
    end

    it "rejects a root of degree zero" do
      expect { evaluate(apply(:root, num("8"), num("0"))) }
        .to raise_error(Dcc::ExtractionError, /degree zero/i)
    end

    it "rejects a zero radicand with a negative degree" do
      expect { evaluate(apply(:root, num("0"), num("-3"))) }
        .to raise_error(Dcc::ExtractionError, /division by zero/i)
    end

    it "rejects ln of zero" do
      expect { evaluate(apply(:ln, num("0"))) }
        .to raise_error(Dcc::ExtractionError, /non-positive/i)
    end

    it "rejects ln of a negative value" do
      expect { evaluate(apply(:ln, num("-1"))) }
        .to raise_error(Dcc::ExtractionError, /non-positive/i)
    end

    it "rejects log of a non-positive value" do
      expect { evaluate(apply(:log, num("0"))) }
        .to raise_error(Dcc::ExtractionError, /non-positive/i)
    end
  end

  # Guarding inputs is not enough: exp(1e100) is Infinity and
  # sin(Infinity) is NaN, both from finite inputs. A non-finite value
  # would then become an operand and poison everything above it.
  describe "non-finite results" do
    it "rejects an exp that overflows to infinity" do
      expect { evaluate(apply(:exp, num("1e100"))) }
        .to raise_error(Dcc::ExtractionError, /non-finite/i)
    end

    it "rejects a power that overflows to infinity" do
      expect { evaluate(apply(:**, num("10"), num("1e30"))) }
        .to raise_error(Dcc::ExtractionError, /non-finite/i)
    end

    it "stops the overflow before it reaches the parent operation" do
      expect { evaluate(apply(:sin, apply(:exp, num("1e100")))) }
        .to raise_error(Dcc::ExtractionError, /exp produced a non-finite/i)
    end

    it "still allows a huge but finite result" do
      expect(result(apply(:exp, num("1000")))).to be_finite
    end
  end

  # Without this, <power/> with one operand quietly computes x ** x and
  # with three quietly drops the middle one.
  describe "operator arity" do
    it "rejects a power with one operand" do
      expect { apply(:**, num("3")) }
        .to raise_error(Dcc::ExtractionError, /takes 2\.\.2/)
    end

    it "rejects a power with three operands" do
      expect { apply(:**, num("2"), num("9"), num("3")) }
        .to raise_error(Dcc::ExtractionError, /takes 2\.\.2/)
    end

    it "rejects a unary function with no operand" do
      expect { apply(:exp) }
        .to raise_error(Dcc::ExtractionError, /takes 1\.\.1/)
    end

    it "rejects a unary function with an extra operand" do
      expect { apply(:abs, num("-3"), num("99")) }
        .to raise_error(Dcc::ExtractionError, /takes 1\.\.1/)
    end

    it "rejects a division with one operand" do
      expect { apply(:/, num("1")) }
        .to raise_error(Dcc::ExtractionError, %r{takes 2\.\.2})
    end

    it "spells out an open-ended arity instead of printing a range" do
      expect { apply(:+) }
        .to raise_error(Dcc::ExtractionError, /takes 1 or more operand/)
    end

    it "leaves the caller's operand array unfrozen" do
      operands = [num("1"), num("2")]
      Dcc::Extract::Formula::Ast::Apply.new(operator: :+, operands: operands)
      expect(operands).not_to be_frozen
    end

    it "allows n-ary addition" do
      expect(evaluate(apply(:+, num("1"), num("2"), num("3"))))
        .to eq([BigDecimal(6)])
    end

    it "allows a unary minus" do
      expect(evaluate(apply(:-, num("5")))).to eq([BigDecimal(-5)])
    end
  end

  # A non-finite *binding* is impossible by construction — Quantity rejects
  # it, which its own spec covers — so only overrides are reachable here.
  describe "non-finite overrides" do
    let(:tree) do
      ast(apply(:exp, var("x")), bindings: { "x" => quantity(BigDecimal(1)) })
    end

    it "rejects an infinite override" do
      expect { described_class.call(tree, "x" => BigDecimal("Infinity")) }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end

    it "rejects a NaN override" do
      expect { described_class.call(tree, "x" => BigDecimal("NaN")) }
        .to raise_error(Dcc::ExtractionError, /not a finite number/i)
    end

    it "rejects an override that is not a number at all" do
      expect { described_class.call(tree, "x" => "banana") }
        .to raise_error(Dcc::ExtractionError, /not a number/i)
    end
  end

  # tan's pole is unreachable: pi/2 is not representable in decimal, so cos
  # comes out as -5.579e-34 rather than zero. Assert what is true.
  describe "tan near its pole" do
    let(:half_pi) { apply(:/, node(:Constant, name: :pi), num("2")) }

    it "stays finite" do
      expect(result(apply(:tan, half_pi))).to be_finite
    end

    it "is very large" do
      expect(result(apply(:tan, half_pi)).abs).to be > BigDecimal("1e30")
    end
  end

  describe "variables and broadcasting" do
    let(:tree) do
      ast(apply(:+, var("x"), num("1")),
          bindings: { "x" => quantity(BigDecimal(1)) })
    end

    let(:list_tree) do
      ast(apply(:+, var("t"), var("k")),
          bindings: { "t" => quantity([1, 2, 3]), "k" => quantity(10) })
    end

    it "reads bindings from the document" do
      expect(described_class.call(tree)).to eq([BigDecimal(2)])
    end

    it "lets overrides win" do
      expect(described_class.call(tree, "x" => 10)).to eq([BigDecimal(11)])
    end

    it "broadcasts element-wise over list variables" do
      expect(described_class.call(list_tree))
        .to eq([BigDecimal(11), BigDecimal(12), BigDecimal(13)])
    end

    it "ignores bindings the formula never references" do
      bindings = { "a" => quantity(1), "unused" => quantity([1, 2, 3]) }

      expect(evaluate(apply(:+, var("a"), num("1")), bindings: bindings))
        .to eq([BigDecimal(2)])
    end

    it "raises when referenced list variables disagree on length" do
      bindings = { "a" => quantity([1, 2]), "b" => quantity([1, 2, 3]) }

      expect { evaluate(apply(:+, var("a"), var("b")), bindings: bindings) }
        .to raise_error(Dcc::ExtractionError, /length/i)
    end

    # A one-element list is still a list. Flattening it to a scalar would
    # let it broadcast against a longer list and quietly return three
    # results instead of raising a mismatch.
    it "treats a one-element list as a list, not a scalar" do
      bindings = { "a" => quantity([5]), "b" => quantity([1, 2, 3]) }

      expect { evaluate(apply(:+, var("a"), var("b")), bindings: bindings) }
        .to raise_error(Dcc::ExtractionError, /length/i)
    end

    it "pairs two one-element lists" do
      bindings = { "a" => quantity([5]), "b" => quantity([7]) }

      expect(evaluate(apply(:+, var("a"), var("b")), bindings: bindings))
        .to eq([BigDecimal(12)])
    end

    it "still broadcasts a true scalar against a list" do
      bindings = { "a" => quantity(5), "b" => quantity([1, 2, 3]) }

      expect(evaluate(apply(:+, var("a"), var("b")), bindings: bindings))
        .to eq([BigDecimal(6), BigDecimal(7), BigDecimal(8)])
    end

    it "raises when a referenced variable has no value" do
      expect { evaluate(apply(:+, var("missing"), num("1"))) }
        .to raise_error(Dcc::ExtractionError, /missing/)
    end
  end
end
