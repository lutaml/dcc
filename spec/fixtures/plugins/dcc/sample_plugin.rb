# frozen_string_literal: true

# Loaded by `Dcc.load_plugins("dcc-sample_plugin")` in `spec/dcc_spec.rb`.
# Stands in for a real `dcc-*` plugin gem's entry file.
class DccSamplePlugin
  include Dcc::Plugin::Base

  # A plugin's own rule, declared as the file loads.
  class SampleRule < ::Dcc::Validate::Schematron::Rules::Base
  end

  register_validator SampleRule
end
