# frozen_string_literal: true

module Dcc
  module Server
    # Pluggable storage for uploaded DCC XML documents. The default
    # `Memory` implementation keeps documents in-process; production
    # deployments can swap in a disk or Redis-backed implementation.
    module Storage
      autoload :Memory, "dcc/server/storage/memory"
      autoload :Entry, "dcc/server/storage/entry"
    end
  end
end