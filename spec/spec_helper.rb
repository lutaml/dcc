# frozen_string_literal: true

require "dcc"
require "canon/rspec_matchers"

Canon::Config.configure do |config|
  config.xml.match.options = {
    comments: :ignore,
    structural_whitespace: :ignore,
    attribute_order: :ignore,
  }
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    # Reset lutaml-model global state between specs to avoid cross-test
    # contamination (per lutaml-model CLAUDE.md).
    if defined?(Lutaml::Model::GlobalContext) &&
       Lutaml::Model::GlobalContext.respond_to?(:clear_caches)
      Lutaml::Model::GlobalContext.clear_caches
    end
    next unless defined?(Lutaml::Model::TransformationRegistry)

    reg = Lutaml::Model::TransformationRegistry
    reg.instance.clear if reg.instance.respond_to?(:clear)
  end
end

Lutaml::Model::Config.configure do |config|
  config.xml_adapter_type = :nokogiri
end

FIXTURES_DIR = File.expand_path("fixtures", __dir__)
FIXTURE_CACHE = {}

def fixtures_path(*parts)
  File.join(FIXTURES_DIR, *parts)
end

def load_fixture(*parts)
  FIXTURE_CACHE[parts] ||= File.read(fixtures_path(*parts))
end

def ptb_fixture(name)
  File.read(fixtures_path("ptb", name))
end
