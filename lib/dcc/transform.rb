# frozen_string_literal: true

# `Dcc::Transform` provides XSLT transformations. We cannot use Nokogiri
# for this per project rule (only validation may touch Nokogiri); instead
# we shell out to the system `xsltproc` CLI for XSLT 1.0, or to
# `java -jar saxon-he.jar` for XSLT 2.0/3.0 when SAXON_JAR is set.
module Dcc
  module Transform
    autoload :Xslt, "dcc/transform/xslt"
    autoload :Result, "dcc/transform/result"
  end
end