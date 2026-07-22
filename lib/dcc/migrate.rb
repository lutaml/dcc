# frozen_string_literal: true

# `Dcc::Migrate` upgrades or downgrades a parsed DCC between schema versions,
# applying the necessary field renames and D-SI version transitions.
#
# Currently a thin shim: serializes the source DCC and re-parses under
# the target version's context. Future work will add per-field transformations.
module Dcc
  module Migrate
    class << self
      # @param dcc [Lutaml::Model::Serializable]
      # @param from [String] source version (e.g. "2.3.0").
      # @param to [String] target version (e.g. "3.3.0").
      # @return [Dcc::V2::DigitalCalibrationCertificate, Dcc::V3::DigitalCalibrationCertificate]
      def call(dcc, from:, to:)
        from_major = ::Dcc::Schema::Version.major(from)
        to_major = ::Dcc::Schema::Version.major(to)
        if from_major == to_major
          # Same major: just rewrite the schemaVersion attribute.
          return rewrite_schema_version(dcc, to)
        end

        # Cross-major migration: serialize then re-parse under target.
        xml = dcc.to_xml
        target_parser = ::Dcc.parser_for(to_major)
        target_parser.load_all!
        migrated = target_parser.parse(xml)
        rewrite_schema_version(migrated, to)
      end

      private

      def rewrite_schema_version(dcc, version)
        return dcc unless Dcc::TypeGuards.has_writer?(dcc, :schema_version)

        dcc.schema_version = version
        dcc
      end
    end
  end
end