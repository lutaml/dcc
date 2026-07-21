# frozen_string_literal: true

module Dcc
  module Transform
    # Output of an XSLT transform.
    class Result
      attr_reader :payload, :engine

      def initialize(payload:, engine:)
        @payload = payload
        @engine = engine
      end

      def to_s
        @payload
      end

      def to_json(*_args)
        require "json"
        ::JSON.pretty_generate(engine: @engine, payload: @payload)
      end
    end
  end
end