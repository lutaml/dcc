# frozen_string_literal: true

# `Dcc::Streaming` walks a DCC document one subtree at a time, so a batch
# pipeline can process a multi-MB certificate without holding the whole
# object tree in memory. Each matched subtree is reconstructed on its own,
# parsed into the version-appropriate model, yielded, and dropped.
#
# @example Walk every calibrated item
#   File.open("certificate.xml") do |io|
#     Dcc::Streaming.each_item(io) { |item| puts item.id }
#   end
#
# @example Take the first two quantities without reading the whole document
#   Dcc::Streaming.each_quantity(io).first(2)
#
# Version detection differs from `Dcc.parse`. Streaming reads `schemaVersion`
# off a real DCC element, so a certificate wrapped in an envelope is detected
# from its own root even when the envelope carries a `schemaVersion` of its
# own. `Dcc.detect_version` scans the document lexically instead, so it also
# matches a `schemaVersion=` inside a comment, inside text or CDATA, on a
# prefixed attribute such as `f:schemaVersion`, or on a foreign wrapper
# element. The two can disagree on those documents, and streaming is the one
# reading the schema's actual attribute. Pass `version:` to settle it.
module Dcc
  module Streaming
    autoload :Reader, "dcc/streaming/reader"

    class << self
      # Yield each `dcc:item` in document order.
      #
      # @param io [IO, StringIO] readable XML stream.
      # @param version [Integer, nil] major DCC version (2 or 3). When nil it
      #   is detected from the first `schemaVersion` attribute seen outside a
      #   matched subtree before the first item is yielded, and falls back to
      #   3. See the note on version detection above.
      # @param context [Symbol, String, nil] substitution context. Defaults
      #   to the version's configured context.
      # @yieldparam [Dcc::V2::Item, Dcc::V3::Item]
      # @return [Enumerator] when no block is given.
      # @raise [Dcc::ParseError] if the stream is not well-formed XML.
      def each_item(io, version: nil,
                    context: ::Dcc::UNSPECIFIED_CONTEXT, &block)
        return enum_for(:each_item, io, version:, context:) unless block

        stream(io, :item, version, context, &block)
      end

      # Yield each outermost `dcc:quantity` in document order.
      #
      # A quantity nested inside another quantity's `influenceConditions` is
      # not yielded on its own — it is reachable from the outer object.
      #
      # @param io [IO, StringIO] readable XML stream.
      # @param version [Integer, nil] major DCC version (2 or 3). Detected the
      #   same way `each_item` detects it when nil.
      # @param context [Symbol, String, nil] substitution context.
      # @yieldparam [Dcc::V2::Quantity, Dcc::V3::Quantity]
      # @return [Enumerator] when no block is given.
      # @raise [Dcc::ParseError] if the stream is not well-formed XML.
      def each_quantity(io, version: nil,
                        context: ::Dcc::UNSPECIFIED_CONTEXT, &block)
        return enum_for(:each_quantity, io, version:, context:) unless block

        stream(io, :quantity, version, context, &block)
      end

      private

      # `version` is validated here rather than on first match, so an
      # unsupported value raises the same way regardless of what the
      # document happens to contain.
      def stream(io, model_id, version, context, &)
        ::Dcc.parser_for(version) if version
        ::Dcc.load_all!
        Reader.call(io, model_id:, version:, context:, &)
      end
    end
  end
end
