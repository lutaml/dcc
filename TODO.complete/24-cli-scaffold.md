# 24 — CLI scaffold (P2)

**Status:** COMPLETED

## Goal
Thor-based CLI dispatching to all Dcc services with human-readable default output and `--format json|yaml` switches.

## Files
- `lib/dcc/cli.rb` — autoloads.
- `lib/dcc/cli/cli.rb` — top-level Thor class with subcommand dispatchers.
- `lib/dcc/cli/commands/validate.rb`, `convert.rb`, `extract.rb`, `signature.rb`, `transform.rb`, `inspect.rb`, `diff.rb`, `issue.rb`.
- `lib/dcc/cli/formatters.rb` — picks `to_s` / `to_json` / `to_yaml` based on `--format`.
- `exe/dcc` already wired.

## Commands
```
dcc validate xsd FILE [--version V|auto]
dcc validate schematron FILE
dcc validate all FILE
dcc convert json|yaml|csv|html FILE [-o OUTPUT]
dcc extract files FILE [INDEX] [-o OUTPUT] [-r RING]
dcc extract formulae FILE [-v KEY=VAL[,VAL...]]...
dcc extract quantities FILE
dcc extract table FILE
dcc signature sign CERT KEY FILE [-o OUTPUT]
dcc signature verify CA_CERT FILE [-o OUTPUT]
dcc transform xslt FILE XSLT [-o OUTPUT] [--engine nokogiri|saxon]
dcc inspect FILE [--format text|json|yaml]
dcc diff A.xml B.xml [--format text|json]
dcc issue   # interactive builder REPL
```

## Design notes
- Every command constructs the appropriate service object, calls `.call`, then hands the result to `Dcc::Cli::Formatters.format(result, format)`.
- Human-readable default uses `tty-table` for tabular outputs.
- Exit codes: 0 on success, 1 on validation failure, 2 on usage error.

## Dependencies
- 14-22 (the services the CLI shells).

## Verification
- `bundle exec exe/dcc --help` lists all commands.
- `bundle exec exe/dcc validate all spec/fixtures/ptb/valid.xml` exits 0.
- `bundle exec exe/dcc inspect spec/fixtures/ptb/valid.xml --format json` produces valid JSON.
