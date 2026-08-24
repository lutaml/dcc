# frozen_string_literal: true

module Dcc
  module Migrate
    # Registry of migrations whose full incompatibility set has been verified
    # against the bundled XSDs.
    #
    # Unregistered pairs raise rather than run. DCC 2.1.0 and 2.1.1 sit in the
    # `https://ptb.de/si/smartcom/d-si/v1_0_1` D-SI namespace, which no
    # transform here addresses, so accepting them by major version alone would
    # silently emit an unmigrated document.
    module Route
      TRANSFORMS = { %w[2.3.0 3.3.0] => :V2ToV3 }.freeze

      # v3.3.0 is a strict superset of v3.2.1 at instance level; only the
      # `schemaVersion` pattern differs.
      SCHEMA_VERSION_ONLY = [%w[3.2.1 3.3.0]].freeze

      class << self
        # @param from [String] normalized source version, e.g. "2.3.0".
        # @param to [String] normalized target version, e.g. "3.3.0".
        # @return [Boolean] whether this migration is registered.
        def supported?(from, to)
          TRANSFORMS.key?([from, to]) ||
            SCHEMA_VERSION_ONLY.include?([from, to])
        end

        # @return [Module, nil] a module responding to
        #   `.call(xml, to:, on_loss:)`, or nil when only `schemaVersion`
        #   needs rewriting.
        def for(from, to)
          name = TRANSFORMS[[from, to]]
          name && ::Dcc::Migrate.const_get(name)
        end

        # @return [Array<String>] every registered pair, for error messages.
        def supported_pairs
          (TRANSFORMS.keys + SCHEMA_VERSION_ONLY)
            .map { |from, to| "#{from} to #{to}" }
        end
      end
    end
  end
end
