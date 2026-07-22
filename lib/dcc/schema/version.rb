# frozen_string_literal: true

# `Dcc::Schema::Version` enumerates the bundled DCC and D-SI schema versions
# and provides lookup helpers. Versions are stored as Strings in semver form
# (e.g. `"3.3.0"`) with an optional `"v"` prefix tolerated on input.
module Dcc
  module Schema
    module Version
      DCC_ALL = %w[
        2.1.0 2.1.1 2.2.0 2.3.0 2.4.0
        3.0.0 3.1.0 3.1.1 3.1.2 3.2.0 3.2.1 3.3.0
      ].freeze

      DCC_LATEST = "3.3.0"
      DCC_DEFAULT = DCC_LATEST

      DSI_ALL = %w[
        1.0.1 1.3.0 1.3.1 2.0.0 2.1.0 2.2.1
      ].freeze

      DSI_LATEST = "2.2.1"
      DSI_DEFAULT = DSI_LATEST

      QUDT_VERSION = "2.2.1"

      class << self
        # Normalize a version input to a bare `"X.Y.Z"` String.
        # @param v [String, Symbol] e.g. `:v3_3_0`, `"3.3.0"`, `"v3.3.0"`.
        # @return [String, nil]
        def normalize(v)
          return nil if v.nil?

          s = v.to_s.sub(/\Av/, "").gsub(/_/, ".")
          s.empty? ? nil : s
        end

        # @param v [String, Symbol] candidate version.
        # @return [Boolean] whether the version is a known DCC release.
        def dcc?(v)
          DCC_ALL.include?(normalize(v))
        end

        # @param v [String, Symbol] candidate version.
        # @return [Boolean] whether the version is a known D-SI release.
        def dsi?(v)
          DSI_ALL.include?(normalize(v))
        end

        # Major version of a semver string (`"3.3.0"` → `3`).
        def major(v)
          Integer(normalize(v).split(".").first)
        end

        # Resolve `:auto`, `nil`, `"latest"`, or a specific version string to
        # a concrete DCC version. The `:auto` strategy reads `schemaVersion`
        # from the XML body.
        def resolve_dcc(version, xml: nil)
          v = normalize(version)
          return detect_from_xml(xml) || DCC_LATEST if v.nil? || v == "auto"
          return DCC_LATEST if v == "latest"

          unless dcc?(v)
            raise ::Dcc::UnknownVersionError,
                  "Unknown DCC schema version: #{version.inspect}"
          end

          v
        end

        def resolve_dsi(version, xml: nil)
          v = normalize(version)
          return DSI_LATEST if v.nil? || v == "auto" || v == "latest"

          unless dsi?(v)
            raise ::Dcc::UnknownVersionError,
                  "Unknown D-SI schema version: #{version.inspect}"
          end

          v
        end

        # Extract the `schemaVersion` attribute from an XML string.
        # @return [String, nil]
        def detect_from_xml(xml)
          return nil unless xml

          str = ::Dcc.read_input(xml)
          match = str.match(/schemaVersion\s*=\s*["']([^"']+)["']/)
          match && match[1]
        end
      end
    end
  end
end
