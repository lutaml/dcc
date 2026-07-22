# frozen_string_literal: true

require_relative "lib/dcc/version"

Gem::Specification.new do |spec|
  spec.name = "dcc"
  spec.version = Dcc::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Digital Calibration Certificate (DCC) and D-SI library for Ruby"
  spec.description = <<~DESCRIPTION
    A Ruby library for parsing, validating, converting, signing, and building
    PTB Digital Calibration Certificates (DCC) and D-SI quantity documents.
    Uses lutaml-model for a fully typed object representation of both XML
    schemas, with per-major-version (v2, v3) class hierarchies.
  DESCRIPTION

  spec.homepage = "https://github.com/lutaml/dcc"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/lutaml/dcc/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features|TODO\.complete)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "lutaml-model", "~> 0.8"
  spec.add_dependency "thor"
end
