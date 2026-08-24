# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"

# Optional dependencies — loaded lazily by the feature that needs them.
group :optional do
  gem "sinatra"      # Dcc::Server REST API
  gem "tty-prompt"   # dcc issue (interactive builder)
  gem "tty-table"    # dcc extract files (aligned table)
end

gem "puma", "~> 8.0"
gem "rackup", "~> 2.3"
