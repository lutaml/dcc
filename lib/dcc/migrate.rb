# frozen_string_literal: true

# `Dcc::Migrate` upgrades a parsed DCC to a newer schema version.
#
# Migration is a document transform: the source is serialised, the route's
# field rules are applied to the XML, and the result is parsed under the
# target version. The input object is never modified.
#
# Migrations are one-way. A downgrade cannot preserve the source — v3 adds
# elements and attributes that no older schema accepts — so downgrading warns
# and then raises rather than returning a quietly invalid document.
module Dcc
  module Migrate
    autoload :Route, "dcc/migrate/route"
    autoload :V2ToV3, "dcc/migrate/v2_to_v3"

    class << self
      # @param dcc [Lutaml::Model::Serializable] parsed DCC.
      # @param from [String] source version, e.g. "2.3.0".
      # @param to [String] target version, e.g. "3.3.0".
      # @raise [Dcc::UnknownVersionError] if either version is not bundled.
      # @raise [Dcc::UnsupportedMigrationError] on a downgrade, or on a pair
      #   whose incompatibilities have not been verified.
      # @return [Dcc::V2::DigitalCalibrationCertificate,
      #   Dcc::V3::DigitalCalibrationCertificate]
      def call(dcc, from:, to:)
        reject_unparsed(dcc)
        source = ::Dcc::Schema::Version.resolve_dcc(from)
        target = ::Dcc::Schema::Version.resolve_dcc(to)
        return dcc if source == target

        reject_downgrade(source, target)
        reject_unregistered(source, target)

        transform = Route.for(source, target)
        xml = transform ? transform.call(dcc.to_xml, to: target) : dcc.to_xml
        parse_as(xml, target)
      end

      private

      def reject_unparsed(dcc)
        return if dcc.is_a?(::Lutaml::Model::Serializable)

        raise ::Dcc::Error,
              "Dcc.migrate expects a parsed DCC document, got " \
              "#{dcc.class}. Parse the XML with Dcc.parse first."
      end

      def reject_downgrade(source, target)
        return if ::Gem::Version.new(target) > ::Gem::Version.new(source)

        message = "Cannot migrate #{source} to #{target}: downgrading " \
                  "discards information the older schema cannot represent."
        Kernel.warn(message)
        raise ::Dcc::UnsupportedMigrationError, message
      end

      def reject_unregistered(source, target)
        return if Route.supported?(source, target)

        raise ::Dcc::UnsupportedMigrationError,
              "No verified migration from #{source} to #{target}. " \
              "Supported: #{Route.supported_pairs.join(', ')}."
      end

      def parse_as(xml, version)
        parser = ::Dcc.parser_for(::Dcc::Schema::Version.major(version))
        parser.load_all!
        parsed = parser.parse(xml)
        parsed.schema_version = version
        parsed
      end
    end
  end
end
