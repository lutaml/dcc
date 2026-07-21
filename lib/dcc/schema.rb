# frozen_string_literal: true

# `Dcc::Schema` provides access to the bundled XSD, Schematron, and QUDT
# resources that ship with the gem under `lib/dcc/schema/resources/`.
#
# Use `Dcc::Schema.path("dcc/v3.3.0/dcc.xsd")` to get the absolute filesystem
# path of a bundled resource. Use `Dcc::Schema::Version` for the canonical
# list of supported versions.
module Dcc
  module Schema
    RESOURCES_DIR = File.expand_path("schema/resources", __dir__).freeze

    autoload :Version, "dcc/schema/version"

    class << self
      # @param relative_path [String, Array<String>] resource path relative to
      #   `lib/dcc/schema/resources/`, e.g. `"dcc/v3.3.0/dcc.xsd"`.
      # @return [String] absolute filesystem path.
      def path(relative_path)
        File.join(RESOURCES_DIR, *Array(relative_path))
      end

      # @return [Boolean] whether the bundled resource exists.
      def exists?(relative_path)
        File.file?(path(relative_path))
      end

      # Read a bundled resource's contents.
      # @return [String]
      def read(relative_path)
        File.read(path(relative_path))
      end
    end
  end
end
