# frozen_string_literal: true

# `Dcc::Server` provides an optional Rack/Sinatra REST API mirroring PTB's
# dcclib REST endpoints. Soft-depends on `sinatra`; raises
# `Dcc::MissingDependencyError` if not installed.
module Dcc
  module Server
    autoload :App, "dcc/server/app"
    autoload :Storage, "dcc/server/storage"

    # Attempt to load sinatra to detect availability.
    def self.available?
      return @available unless @available.nil?

      begin
        require "sinatra/base"
        @available = true
      rescue ::LoadError
        @available = false
      end
      @available
    end

    # Raise a friendly error if Sinatra is missing.
    def self.ensure_available!
      return if available?

      raise ::Dcc::MissingDependencyError.new(gem_name: "sinatra",
                                              feature: "Dcc::Server REST API"),
            "sinatra is required for the REST API"
    end
  end
end