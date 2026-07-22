# frozen_string_literal: true

require "digest"

module Dcc
  module Server
    module Storage
      # In-memory storage with SHA-256-keyed entries and TTL eviction.
      # Not thread-safe without external synchronization — wrap in a
      # Mutex for concurrent deployments.
      class Memory
        attr_reader :ttl_seconds

        def initialize(ttl_seconds: 300)
          @store = {}
          @ttl_seconds = ttl_seconds
        end

        # @param xml [String]
        # @return [Dcc::Server::Storage::Entry]
        def put(xml)
          id = ::Digest::SHA256.hexdigest(xml)
          entry = Entry.new(id: id, xml: xml, expires_at: Time.now + ttl_seconds)
          @store[id] = entry
          entry
        end

        # @param id [String] SHA-256 hex.
        # @return [Dcc::Server::Storage::Entry, nil]
        def get(id)
          entry = @store[id]
          return nil unless entry

          if entry.expired?
            @store.delete(id)
            return nil
          end
          entry
        end

        # @param id [String]
        # @return [Boolean]
        def delete(id)
          !!@store.delete(id)
        end

        def clear
          @store.clear
        end

        def size
          @store.size
        end
      end
    end
  end
end