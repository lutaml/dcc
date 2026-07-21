# 01 — Scaffolding (P0)

**Status:** COMPLETED

## Goal
Stand up the gem skeleton: gemspec, dependencies, build tooling, lib entry point.

## Files created
- `dcc.gemspec` — modelled on reqif.gemspec; deps: `lutaml-model ~> 0.8`, `nokogiri`, `thor`.
- `Gemfile` — dev deps + GitHub lutaml-model + optional group (`sinatra`, `tty-prompt`, `xmldsig`).
- `Rakefile` — `bundler/gem_tasks`, rspec, rubocop; default = spec + rubocop.
- `.rspec`, `.rubocop.yml`, `.rubocop_todo.yml`, `.gitignore`, `LICENSE` (MIT).
- `exe/dcc` — Thor CLI stub (`Dcc::Cli::Cli.start(ARGV)`).
- `lib/dcc.rb` — top-level namespace, `autoload`s, `Dcc.parse/build/migrate/parser_for/detect_version`, `SUPPORTED_VERSIONS = [2, 3]`.
- `lib/dcc/version.rb` — `Dcc::VERSION = "0.1.0"`.
- `spec/spec_helper.rb` — Canon matchers, Nokogiri adapter, global state reset before each spec, fixture helpers.

## Design notes
- Ruby >= 3.2 (consistent with TargetRubyVersion 3.2 in .rubocop.yml).
- All `lib/dcc/**.rb` files use autoload (never `require_relative`), per global rule.
- TODO.complete/ excluded from gem package via gemspec `reject` filter.

## Verification
- `bundle install` succeeds.
- `bundle exec ruby -e 'require "dcc"'` loads without error.
- `bundle exec rubocop` passes (modulo rubocop_todo).
- `bundle exec rake` runs the empty spec suite cleanly.
