# Changelog

This file records all notable changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-10-29

### Added

- `MAX_NESTING_DEPTH`, with `Parse_Error.Too_Deeply_Nested` and `Render_Error.Nesting_Depth_Exceeded`.

### Fixed

- Text after an included partial that has no final newline no longer gets the outer partial's indentation a second time.
- Deeply nested sections no longer overflow the stack: `compile` rejects templates nested deeper than `MAX_NESTING_DEPTH`, and `render` stops recursive partials at the same depth.
- A zero `Partials` value now uses `context.allocator`. Before, it kept empty copies of partials added without `partials_init`, so they rendered as nothing.
- `{{=}}` and other set delimiter tags without a closing `=` now fail with `Invalid_Delimiters` instead of `Unclosed_Tag`.

## [0.1.0] - 2026-10-29

### Added

- `compile` and `compile_with_location`, which parse a template into a reusable `Template` syntax tree and report the line and column of a `Parse_Error`.
- `render`, `render_to_writer` and `render_string` for `Value` data, and `render_json` and `render_json_to_writer` for `core:encoding/json` values read in place.
- Support for the Mustache specification v1.4.3: escaped and unescaped variables, dotted names, the implicit iterator, sections, inverted sections, comments, partials, dynamic partial names, set delimiters and standalone lines.
- `Partials`, a registry of compiled partials with standalone indentation and a `MAX_PARTIAL_DEPTH` limit against runaway recursion.
- The `Value` data model with `Object`, `List` and `Map`, plus `from_json` and `value_destroy`.
- Tests generated from the official specification suites, and examples under `examples/basic` and `examples/json`.

[Unreleased]: https://github.com/alexisbcz/odin-mustache/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/alexisbcz/odin-mustache/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/alexisbcz/odin-mustache/releases/tag/v0.1.0
