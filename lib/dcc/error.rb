# frozen_string_literal: true

module Dcc
  # Base error class for all dcc gem errors. Subclasses live directly under
  # `Dcc::Error::*` (e.g. `Dcc::ParseError`).
  class Error < StandardError; end

  # Raised when an XML document cannot be parsed (malformed XML, encoding
  # issues, IO errors).
  class ParseError < Error; end

  # Base class for all validation failures (XSD, Schematron, business rules).
  class ValidationError < Error
    attr_reader :issues

    def initialize(message, issues: [])
      @issues = issues
      super(message)
    end
  end

  # Raised when an XSD validation fails or the XSD itself cannot be loaded.
  class SchemaError < ValidationError; end

  # Raised when XMLDSig signing or verification fails.
  class SignatureError < Error; end

  # Raised when a converter cannot produce the requested output format.
  class ConversionError < Error; end

  # Raised when an extractor encounters malformed content.
  class ExtractionError < Error; end

  # Raised when an XSLT transform fails.
  class TransformError < Error; end

  # Raised when an unsupported schema version is requested.
  class UnknownVersionError < Error; end

  # Raised when the builder DSL is used incorrectly.
  class BuilderError < Error; end

  # Raised when a soft dependency (`xmldsig`, `sinatra`, etc.) is required
  # but not installed.
  class MissingDependencyError < Error
    attr_reader :gem_name, :feature

    def initialize(gem_name:, feature:)
      @gem_name = gem_name
      @feature = feature
      super("The '#{gem_name}' gem is required for #{feature}. Add it to your Gemfile or run: gem install #{gem_name}")
    end
  end
end
