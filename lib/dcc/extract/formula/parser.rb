# frozen_string_literal: true

require "rexml/document"

module Dcc
  module Extract
    module Formula
      # `Dcc::Extract::Formula::Parser` parses a content-MathML string into
      # an AST. Uses REXML (stdlib) — Nokogiri is banned outside validation.
      module Parser
        class << self
          # @param mathml [String] content-MathML XML.
          # @return [Dcc::Extract::Formula::Ast::*]
          def parse(mathml)
            doc = ::REXML::Document.new(mathml)
            root = doc.root
            raise ::Dcc::ExtractionError, "empty MathML document" unless root

            build_from(root)
          end

          private

          def build_from(element)
            case element.name
            when "math"
              child = first_meaningful_child(element)
              child ? build_from(child) : Ast::Number.new(BigDecimal("0"))
            when "declare" then build_from(first_meaningful_child(element) || element)
            when "lambda"
              bvars = []
              body = nil
              element.elements.each do |child|
                if child.name == "bvar"
                  bvars << bvar_name(child)
                else
                  body = build_from(child)
                end
              end
              ::Dcc::Extract::Formula::Ast::Lambda.new(bvars, body || ::Dcc::Extract::Formula::Ast::Number.new(BigDecimal("0")))
            when "bvar" then ::Dcc::Extract::Formula::Ast::BoundVariable.new(bvar_name(element))
            when "ci"
              xref = element.attributes["xref"]
              ::Dcc::Extract::Formula::Ast::Identifier.new(text_of(element), xref)
            when "cn"
              ::Dcc::Extract::Formula::Ast::Number.new(BigDecimal(text_of(element)))
            when "apply"
              children = meaningful_children(element).to_a
              return ::Dcc::Extract::Formula::Ast::Number.new(BigDecimal("0")) if children.empty?

              head = head_of(children.first)
              args = children.drop(1).map { |c| build_from(c) }
              ::Dcc::Extract::Formula::Ast::Apply.new(head, args)
            else
              # An empty or unknown element becomes a no-op zero.
              ::Dcc::Extract::Formula::Ast::Number.new(BigDecimal("0"))
            end
          end

          def head_of(element)
            element.name.to_sym
          end

          def bvar_name(bvar_element)
            inner = first_meaningful_child(bvar_element)
            inner ? text_of(inner) : "x"
          end

          def first_meaningful_child(element)
            meaningful_children(element).first
          end

          def meaningful_children(element)
            element.elements.reject { |e| e.is_a?(::REXML::Text) }
          end

          def text_of(element)
            txt = element.texts.map(&:to_s).join
            txt.strip
          end
        end
      end
    end
  end
end