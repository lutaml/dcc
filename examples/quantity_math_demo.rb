#!/usr/bin/env ruby
# frozen_string_literal: true

# Demonstrate BigDecimal-based quantity math with uncertainty propagation.
#
# Usage:
#   bundle exec examples/quantity_math_demo.rb

require "dcc"
require "bigdecimal"

ten_k   = Dcc::QuantityMath::Real.new(value: BigDecimal("10"),
                                       unit: "\\kelvin",
                                       uncertainty: BigDecimal("0.1"))
twenty_k = Dcc::QuantityMath::Real.new(value: BigDecimal("20"),
                                        unit: "\\kelvin",
                                        uncertainty: BigDecimal("0.2"))

puts "ten:      #{ten_k}"
puts "twenty:   #{twenty_k}"
puts "sum:      #{ten_k + twenty_k}"
puts "product:  #{ten_k * twenty_k}"
puts "ratio:    #{twenty_k / ten_k}"

# Pretty-print with SmartCom-style formats.
fmt = Dcc::QuantityFormat::Formatter.new(value: BigDecimal("42.00"),
                                          uncertainty: BigDecimal("0.05"),
                                          unit: "\\kelvin")
puts
puts "Short:    #{fmt.to_short}"
puts "Long:     #{fmt.to_long}"
puts "LaTeX:    #{fmt.to_latex}"
