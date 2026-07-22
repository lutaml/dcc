# 45 — Eliminate all respond_to? calls from lib/ (P0)

**Status:** COMPLETED

## Goal
67 `respond_to?` calls remain in lib/ despite the project rule:
"NEVER use `respond_to?` for type checking. Use `is_a?` for type checks."

Replace every one with either:
1. `Dcc::TypeGuards.read_attribute(node, :name)` — safe attribute read
2. `Dcc::TypeGuards.digital_calibration_certificate?(node)` — type check
3. `node.is_a?(SpecificClass)` — direct type check
4. `node.class.attributes.key?(:name)` — declared-attribute check

## Categories
- Schematron rules (~35): check sections/attributes before accessing
- Inspect report (~12): check DCC structure before reading counts
- Convert CSV/HTML (~10): check sections before converting
- I18n (~3): check text/content structure
- Builder (1): apply_attrs
- Diff (2): attribute comparison
- Migrate (1): schema_version= check
- CLI (1): $stdout.tty? check — this is stdlib IO duck-typing, acceptable

## Verification
- `grep -rn "respond_to?" lib/ | grep -v comment` returns 0 lines
- `bundle exec rspec` still passes
