# frozen_string_literal: true

module Dcc
  module QuantityFormat
    # SmartCom-style quantity pretty-printing. Significant digits derived
    # from uncertainty (PTB convention: 2 sig digits in uncertainty).
    class Formatter
      attr_reader :value, :uncertainty, :unit

      # @param value [BigDecimal, Numeric]
      # @param uncertainty [BigDecimal, Numeric, nil]
      # @param unit [String, nil] siunitx expression
      def initialize(value:, uncertainty: nil, unit: nil)
        @value = BigDecimal(value.to_s)
        @uncertainty = uncertainty.nil? ? nil : BigDecimal(uncertainty.to_s)
        @unit = unit
      end

      # @return [String] compact notation: `42.00(5) K`
      def to_short
        return format_value.to_s + unit_suffix if uncertainty.nil?

        v_str, u_str = align_value_and_uncertainty
        "#{v_str}(#{u_str})#{unit_suffix}"
      end

      # @return [String] verbose: `42.00 ± 0.05 K`
      def to_long
        if uncertainty.nil?
          "#{format_value}#{unit_suffix}"
        else
          "#{format_value} ± #{format_uncertainty}#{unit_suffix}"
        end
      end

      # @return [String] LaTeX siunitx: `\qty{42.00 +- 0.05}{\kelvin}`
      def to_latex
        if uncertainty.nil?
          "\\qty{#{format_value}}{#{unit || ''}}"
        else
          "\\qty{#{format_value} +- #{format_uncertainty}}{#{unit || ''}}"
        end
      end

      private

      def format_value
        # Two decimals by default, tightened to the uncertainty's precision
        # when it has any. Neither a nil nor a NaN uncertainty has one.
        return @value.round(2).to_s("F") if uncertainty.nil? || uncertainty.nan?

        @value.round(decimal_places).to_s("F")
      end

      def format_uncertainty
        return "" if uncertainty.nil?
        return "NaN" if uncertainty.nan?

        uncertainty.round(decimal_places).to_s("F")
      end

      def align_value_and_uncertainty
        return [@value.to_s("F"), uncertainty.to_s("F")] if uncertainty.nil?
        return [format_value, "NaN"] if uncertainty.nan?

        v_str = @value.round(decimal_places).to_s("F")
        u_str = uncertainty.round(decimal_places).to_s("F")
        # Short form: digits of uncertainty after the last common digit
        last_digits = u_str.gsub(/[^0-9]/, "")[-2..]
        [v_str, last_digits]
      end

      # Decimal places = 1 - floor(log10(uncertainty)). D-SI writes `NaN` for a
      # not-measured entry (SI_Format.xsd:1195) and `Math.log10` cannot answer
      # for it, so every caller excludes nil and NaN first.
      def decimal_places
        [0, 1 - Integer(Math.log10(uncertainty.to_f).floor)].max
      end

      def unit_suffix
        return "" if unit.nil? || unit.empty?

        " #{human_unit}"
      end

      def human_unit
        unit
          .to_s
          .gsub(/\\([a-z]+)/, '\\1') # \kelvin → kelvin
          .gsub("\\per", "/")
          .gsub("\\cubic", "^3")
          .gsub("\\square", "^2")
      end
    end
  end
end
