# frozen_string_literal: true

# Loads Sinatra lazily so the gem works without it installed.
begin
  require "sinatra/base"
  SINATRA_AVAILABLE = true
rescue ::LoadError
  SINATRA_AVAILABLE = false
end

module Dcc
  module Server
    # Sinatra application exposing the DCC REST API. Mirrors PTB dcclib's
    # endpoints: POST /dccs, GET /dccs/:id, DELETE /dccs/:id,
    # POST /dccs/:id/validate/{xsd,schematron}, /convert/json,
    # /extract/{files,formulae}, /signature, /transform/xslt.
    #
    # Run via:
    #   require "dcc/server"
    #   Dcc::Server::App.run!
    class App < ::Sinatra::Base
      before do
        content_type :json
      end

      # Storage instance — override in config.ru for production swaps.
      set :storage, ::Dcc::Server::Storage::Memory.new

      get "/" do
        {
          title: "dcc gem REST API",
          version: ::Dcc::VERSION,
          endpoints: [
            "POST /dccs",
            "GET /dccs/:id",
            "DELETE /dccs/:id",
            "POST /dccs/:id/validate/xsd",
            "POST /dccs/:id/validate/schematron",
            "POST /dccs/:id/convert/json",
            "GET /dccs/:id/extract/files",
            "POST /dccs/:id/transform/xslt",
          ],
        }.to_json
      end

      post "/dccs" do
        ensure_loaded!
        body = JSON.parse(request.body.read)
        xml = body.fetch("xml")
        entry = settings.storage.put(xml)
        status 201
        { id: entry.id, expires: entry.expires_at }.to_json
      rescue ::KeyError
        status 400
        { error: "missing 'xml' in request body" }.to_json
      end

      get "/dccs/:id" do
        entry = settings.storage.get(params[:id])
        halt 404, { error: "not found" }.to_json unless entry

        { id: entry.id, xml: entry.xml, expires: entry.expires_at }.to_json
      end

      delete "/dccs/:id" do
        deleted = settings.storage.delete(params[:id])
        halt 404, { error: "not found" }.to_json unless deleted

        status 204
      end

      post "/dccs/:id/validate/xsd" do
        result = with_dcc(params[:id]) { |xml| ::Dcc::Validate::Xsd.call(xml) }
        result.to_json
      end

      post "/dccs/:id/validate/schematron" do
        result = with_dcc(params[:id]) { |xml| ::Dcc::Validate::Schematron.call(::Dcc.parse(xml)) }
        result.to_json
      end

      post "/dccs/:id/convert/json" do
        with_dcc(params[:id]) do |xml|
          ::Dcc::Convert::Json.call(::Dcc.parse(xml)).payload
        end
      end

      get "/dccs/:id/extract/files" do
        with_dcc(params[:id]) do |xml|
          files = ::Dcc::Extract::File.each(::Dcc.parse(xml))
          {
            files: files.map do |f|
              {
                name: f.name, file_name: f.file_name,
                mime_type: f.mime_type, ring: f.ring.to_s,
                data_base64: ::Base64.strict_encode64(f.data),
              }
            end,
          }.to_json
        end
      end

      post "/dccs/:id/transform/xslt" do
        body = JSON.parse(request.body.read)
        xslt = body.fetch("xslt")
        with_dcc(params[:id]) do |xml|
          ::Dcc::Transform::Xslt.call(xml, xslt).payload
        end
      end

      private

      def ensure_loaded!
        return if @loaded

        ::Dcc.load_all!
        @loaded = true
      end

      def with_dcc(id)
        entry = settings.storage.get(id)
        halt 404, { error: "not found" }.to_json unless entry

        ensure_loaded!
        result = yield(entry.xml)
        result.is_a?(::String) ? result : result.to_json
      end
    end
  end
end

require "base64"
require "json"