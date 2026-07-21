# frozen_string_literal: true

# `Dcc::Si::Base` hosts version-agnostic XML mapping modules for every D-SI
# element type. Mirrors the `Dcc::Base` pattern: each module uses
# `self.included(klass)` with `klass.class_eval` to inject attributes and
# the `xml do ... end` mapping block.
module Dcc
  module Si
    module Base
      autoload :Real, "dcc/si/base/real"
      autoload :Complex, "dcc/si/base/complex"
      autoload :Constant, "dcc/si/base/constant"
      autoload :RealListXmlList, "dcc/si/base/real_list_xml_list"
      autoload :ComplexListXmlList, "dcc/si/base/complex_list_xml_list"
      autoload :Hybrid, "dcc/si/base/hybrid"
      autoload :SiList, "dcc/si/base/si_list"
      autoload :StandardMU, "dcc/si/base/standard_mu"
      autoload :ExpandedMU, "dcc/si/base/expanded_mu"
      autoload :CoverageIntervalMU, "dcc/si/base/coverage_interval_mu"
      autoload :ExpandedUncXmlList, "dcc/si/base/expanded_unc_xml_list"
      autoload :MeasurementUncertaintyUnivariate, "dcc/si/base/measurement_uncertainty_univariate"
    end
  end
end