# frozen_string_literal: true

module Dcc
  module Server
    module Storage
      # Value object for a stored DCC entry. Carries the SHA-256 id, XML
      # payload, and expiry timestamp.
      Entry = ::Struct.new(:id, :xml, :expires_at, keyword_init: true) do
        def expired?
          expires_at && Time.now > expires_at
        end
      end
    end
  end
end