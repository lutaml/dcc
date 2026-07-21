# frozen_string_literal: true

require "bigdecimal"
require "bigdecimal/math"

module Dcc
  # `Dcc::QuantityMath` provides BigDecimal-based arithmetic on D-SI
  # quantities with proper uncertainty propagation. RSS (root-sum-square)
  # for addition/subtraction, fractional for multiplication/division.
  module QuantityMath
    autoload :Quantity, "dcc/quantity_math/quantity"
    autoload :Real, "dcc/quantity_math/real"
  end
end