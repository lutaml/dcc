# frozen_string_literal: true

# `Dcc::Migrate` upgrades a DCC to a newer schema version.
#
# Migration is a document transform: the route's field rules are applied to
# the XML and the result is parsed under the target version. The input is
# never modified.
#
# Pass the source XML when you have it. Passing a parsed model instead costs
# whatever that model could not round-trip, because the model has to be
# serialised back to XML before the transform can see it — the transform
# cannot report a construct the parse already dropped.
#
# Migrations are one-way. A downgrade cannot preserve the source — v3 adds
# elements and attributes that no older schema accepts — so downgrading warns
# and then raises rather than returning a quietly invalid document.
module Dcc
  module Migrate
    autoload :Route, "dcc/migrate/route"
    autoload :V2ToV3, "dcc/migrate/v2_to_v3"

    class << self
      # @param input [String, IO, Lutaml::Model::Serializable] DCC source XML,
      #   or a parsed DCC. Prefer the source XML: see the note on this module.
      # @param from [String] source version, e.g. "2.3.0".
      # @param to [String] target version, e.g. "3.3.0".
      # @raise [Dcc::UnknownVersionError] if either version is not bundled.
      # @raise [Dcc::UnsupportedMigrationError] on a downgrade, or on a pair
      #   whose incompatibilities have not been verified.
      # @return [Dcc::V2::DigitalCalibrationCertificate,
      #   Dcc::V3::DigitalCalibrationCertificate] always a parsed DCC.
      def call(input, from:, to:)
        source = ::Dcc::Schema::Version.resolve_dcc(from)
        target = ::Dcc::Schema::Version.resolve_dcc(to)
        return same_version_result(input, target) if source == target

        reject_downgrade(source, target)
        reject_unregistered(source, target)

        transform = Route.for(source, target)
        xml = source_xml(input)
        parse_as(transform ? transform.call(xml, to: target) : xml, target)
      end

      private

      # A same-version call must not round-trip a model through XML: that
      # would apply the parse loss this transform exists to avoid. The model
      # is still checked, so the no-op path cannot hand back a non-DCC object
      # the other paths would have refused.
      #
      # The version is checked too. Every other route re-parses under the
      # target, so its result carries the requested version whatever `from:`
      # said. This route returns the input untouched, so a mis-declared
      # `from:` would hand back a document of some other version and make both
      # parameters meaningless.
      def same_version_result(input, target)
        if dcc_document?(input)
          reject_version_mismatch(input, target)
          return input
        end

        parse_as(source_xml(input), target)
      end

      def reject_version_mismatch(dcc, target)
        actual = dcc.schema_version
        return if actual.nil? || actual == target

        raise ::Dcc::Error,
              "Dcc.migrate was asked for #{target} but the document " \
              "declares #{actual}."
      end

      # The one place an input becomes XML, and the one place the DCC root is
      # checked.
      #
      # The root check belongs here rather than in the transform: the
      # schemaVersion-only and same-version routes never reach a transform,
      # and any `Serializable` serialises happily, so both would otherwise
      # turn a foreign document into an empty certificate.
      def source_xml(input)
        V2ToV3.assert_dcc_root(raw_xml(input))
      end

      # `Dcc.read_input` falls through to `to_s` for anything that is not
      # IO-like, so the parsed-model case has to be answered first.
      def raw_xml(input)
        return input.to_xml if input.is_a?(::Lutaml::Model::Serializable)

        reject_untranslatable(input)
        ::Dcc.read_input(input)
      end

      # The two DCC root models. Checked by class rather than by serialising
      # and re-reading, so the same-version no-op stays a no-op.
      def dcc_document?(input)
        input.is_a?(::Dcc::V2::DigitalCalibrationCertificate) ||
          input.is_a?(::Dcc::V3::DigitalCalibrationCertificate)
      end

      def reject_untranslatable(input)
        return if input.is_a?(::String) || ::Dcc.io_like?(input)

        raise ::Dcc::Error,
              "Dcc.migrate expects DCC source XML or a parsed DCC document, " \
              "got #{input.class}."
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
