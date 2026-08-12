# frozen_string_literal: true

require "moxml"

module Dcc
  module Streaming
    # SAX handler that reconstructs each matched subtree as a standalone XML
    # fragment, parses it into the version-appropriate model, yields it, and
    # drops it. Only one subtree is buffered at a time, so peak memory tracks
    # the largest single subtree rather than the document.
    #
    # The fragment reproduces the XML infoset, not the original bytes.
    # Entity references arrive expanded, CDATA becomes text, processing
    # instruction spacing is normalised, and every namespace in scope is
    # re-declared on the fragment root so prefixes still resolve once the
    # subtree is detached.
    class Reader < ::Moxml::SAX::Handler
      # Stream `io`, yielding one model per matched subtree.
      #
      # @param io [IO, StringIO] readable XML stream.
      # @param model_id [Symbol] registered model id, `:item` or `:quantity`.
      # @param version [Integer, nil] major DCC version. When nil it is read
      #   from the first `schemaVersion` attribute seen outside a matched
      #   subtree before the first model is yielded, and falls back to 3.
      #   `Dcc.detect_version` instead scans the whole document lexically,
      #   because it is not restricted to a single pass.
      # @param context [Symbol, String, nil] substitution context.
      # @return [void]
      # @raise [Dcc::ParseError] if the stream is not well-formed XML. A
      #   failing IO also surfaces this way, with the original IO message
      #   replaced by the parser's — libxml2 does not pass it through.
      def self.call(io, model_id:, version:, context:, &)
        handler = new(model_id:, version:, context:, &)
        adapter = ::Lutaml::Model::Config.xml_adapter_type
        ::Moxml.new(adapter).sax_parse(io, handler)
      end

      # A handler carries one document's worth of state, so `.call` builds a
      # fresh one per stream and construction stays closed.
      private_class_method :new

      def initialize(model_id:, version:, context:, &block)
        super()
        @model_id = model_id
        @major = version
        @context = context
        @block = block
        @scopes = [{}]
        @subtree = nil
        @depth = 0
      end

      # Declarations are merged and snapshotted before the element's own
      # prefix is resolved, so an element that rebinds its prefix matches on
      # its new binding rather than the inherited one.
      def on_start_element(name, attributes = {}, namespaces = {})
        # Almost no element declares a namespace, so merging every time would
        # allocate a copy of the parent scope per element. Scopes are only
        # ever read, so the unchanged ones can share one hash.
        @scopes.push(
          namespaces.empty? ? @scopes.last : @scopes.last.merge(namespaces),
        )
        return begin_subtree(name, attributes) unless @subtree

        @depth += 1
        @subtree.start_element(name, attributes, namespaces)
      end

      def on_end_element(name)
        finish_element(name) if @subtree
        @scopes.pop
      end

      def on_characters(text)
        @subtree&.characters(text)
      end

      def on_cdata(text)
        @subtree&.characters(text)
      end

      def on_comment(text)
        @subtree&.comment(text)
      end

      def on_processing_instruction(target, data)
        @subtree&.processing_instruction(target, data)
      end

      # Translated here rather than around the whole parse, so an exception
      # raised by the consumer block travels untouched instead of being
      # reported as malformed input.
      def on_error(error)
        raise ::Dcc::ParseError, error.message
      end

      private

      # Only elements outside a matched subtree get a say in the version, so a
      # `schemaVersion` on a descendant — or inside an opaque `dcc:xml` blob —
      # cannot choose the parser for the whole stream.
      def begin_subtree(name, attributes)
        @major ||= schema_version_major(name, attributes)
        return unless match?(name)

        @depth = 0
        @subtree = Subtree.new(name, attributes, @scopes.last)
      end

      def finish_element(name)
        @subtree.end_element(name)
        if @depth.zero?
          emit(@subtree.to_xml)
          @subtree = nil
        else
          @depth -= 1
        end
      end

      def emit(xml)
        @block.call(model_class.from_xml(xml, register: context_id))
      end

      def match?(name)
        split(name).last == @model_id.to_s && dcc_element?(name)
      end

      def dcc_element?(name)
        dcc_namespace?(@scopes.last[split(name).first])
      end

      # `Dcc::Namespace::Dcc` also accepts the `.xsd` alias that older PTB
      # documents bind, so streaming matches whatever `Dcc.parse` accepts.
      def dcc_namespace?(uri)
        namespace = ::Dcc::Namespace::Dcc
        uri == namespace.uri || namespace.uri_aliases.include?(uri)
      end

      def split(name)
        prefix, local = name.split(":", 2)
        local ? [prefix, local] : [nil, prefix]
      end

      # Resolved through the registry rather than referenced directly, so a
      # configured custom model substitutes the root class too.
      def model_class
        @model_class ||=
          ::Lutaml::Model::GlobalContext.resolve_type(@model_id, context_id)
      end

      def context_id
        @context_id ||= ::Dcc::ContextOptions.normalize_context_option(
          context: @context,
          register: nil,
          default_context: configuration.default_context_id,
          warning_source: "Dcc::Streaming",
        )
      end

      def configuration
        ::Dcc.parser_for(major)::Configuration
      end

      # `schemaVersion` sits on the DCC root, which is not always the document
      # root — a certificate can arrive wrapped in an envelope. Only a DCC
      # element settles the version, so a wrapper carrying a `schemaVersion`
      # of its own does not retype the certificate nested inside it.
      def schema_version_major(name, attributes)
        version = attributes["schemaVersion"]
        return unless version && dcc_element?(name)

        ::Dcc.major_version_from(version)
      end

      # A document that declares `schemaVersion` nowhere falls back the way an
      # unusable one does, so `Dcc` keeps deciding that rather than a literal
      # repeated here. The answer is written back rather than defaulted on
      # each read: the model class and the context are memoised off this at
      # the first yield, so a `schemaVersion` appearing later must not move
      # the version out from under them.
      def major
        @major ||= ::Dcc.major_version_from(nil)
      end

      # Accumulates the raw XML of a single matched subtree.
      #
      # SAX hands over decoded characters, so control whitespace has to go
      # back as character references. Written literally it would be
      # normalised a second time on reparse — a carriage return in text
      # would arrive as a newline, and a tab or newline in an attribute
      # would collapse to a space.
      #
      # C14N mandates exactly that set of character references, so moxml's
      # encoder is reused rather than restating the table here.
      class Subtree
        def initialize(name, attributes, scope)
          @buffer = +""
          write_start(name, attributes, scope)
        end

        def start_element(name, attributes, namespaces)
          write_start(name, attributes, namespaces)
        end

        def end_element(name)
          @buffer << "</#{name}>"
        end

        def characters(text)
          @buffer << ::Moxml::C14n.escape_text(text)
        end

        def comment(text)
          @buffer << "<!--#{text}-->"
        end

        def processing_instruction(target, data)
          @buffer << "<?#{target} #{data}?>"
        end

        def to_xml
          @buffer
        end

        private

        def write_start(name, attributes, namespaces)
          @buffer << "<#{name}"
          namespaces.each do |prefix, href|
            write_attribute(prefix ? "xmlns:#{prefix}" : "xmlns", href)
          end
          attributes.each do |key, value|
            write_attribute(key, decode_ampersands(value))
          end
          @buffer << ">"
        end

        # SAX decodes an attribute value except for `&`, which libxml2 hands
        # back still written as the decimal reference `&#38;` whatever form
        # the source used. Escaping that would emit `&amp;#38;`, and the value
        # would come back one round trip more corrupt each time. A bare `&`
        # never reaches us, which is what makes putting it back exact rather
        # than a guess.
        #
        # Namespace URIs and character data do not come through here: moxml
        # hands those over fully decoded, and a URI carrying a literal `&#38;`
        # would be corrupted by this substitution. Re-measure both channels if
        # the moxml dependency moves.
        # Most attributes carry no `&#38;`, and `gsub` allocates a copy even
        # when it substitutes nothing. Measured over 300k calls: the guard is
        # about twice as fast when there is no match, and about 13% slower on
        # the rare value that does match.
        def decode_ampersands(value)
          return value unless value.include?("&#38;")

          value.gsub("&#38;", "&")
        end

        def write_attribute(name, value)
          escaped = ::Moxml::C14n.escape_attribute(value)
          @buffer << %( #{name}="#{escaped}")
        end
      end
      private_constant :Subtree
    end
  end
end
