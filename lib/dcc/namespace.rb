# frozen_string_literal: true

# `Dcc::Namespace` aggregates the five XML namespaces used by DCC documents:
#
# * `dcc:`  — the Digital Calibration Certificate itself (https://ptb.de/dcc)
# * `si:`   — D-SI quantity values (https://ptb.de/si)
# * `ml:`   — MathML formulae (http://www.w3.org/1998/Math/MathML)
# * `ds:`   — W3C XML Digital Signature (http://www.w3.org/2000/09/xmldsig#)
# * `qudt:` — QUDT quantity kinds (http://qudt.org/vocab/)
module Dcc
  module Namespace
    autoload :Dcc, "dcc/namespace/dcc"
    autoload :Si, "dcc/namespace/si"
    autoload :MathMl, "dcc/namespace/math_ml"
    autoload :Dsig, "dcc/namespace/dsig"
    autoload :Qudt, "dcc/namespace/qudt"
  end
end
