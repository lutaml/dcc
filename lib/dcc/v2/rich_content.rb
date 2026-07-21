# frozen_string_literal: true

# DCC v2.x has no `dcc:richContentType`; the v3.4+ type doesn't apply. For
# forward compatibility we register a V2 `RichContent` that simply reuses
# the V2 `Text` mapping so documents parsed under `:dcc_v2` context resolve
# the `:richContent` symbol.
module Dcc::V2
  class RichContent < CommonElements
    include ::Dcc::Base::Text
  end
  Configuration.register_model(RichContent, id: :richContent)
end
