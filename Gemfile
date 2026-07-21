# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon"
gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"
gem "moxml"
gem "nokogiri"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "tty-table"

# Optional dependencies — loaded lazily by the feature that needs them.
group :optional do
  gem "sinatra"      # Dcc::Server REST API
  gem "tty-prompt"   # dcc issue (interactive builder)
  gem "xmldsig"      # Dcc::Signature
end
