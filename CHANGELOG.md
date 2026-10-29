# Changelog

This file records all notable changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-29

### Added

- `compile` and `compile_with_location`, which parse a template into a reusable `Template` syntax tree and report the line and column of a `Parse_Error`.
- `render`, `render_to_writer` and `render_string` for `Value` data, and `render_json` and `render_json_to_writer` for `core:encoding/json` values read in place.
- Support for the Mustache specification v1.4.3: escaped and unescaped variables, dotted names, the implicit iterator, sections, inverted sections, comments, partials, dynamic partial names, set delimiters and standalone lines.
- `Partials`, a registry of compiled partials with standalone indentation and a `MAX_PARTIAL_DEPTH` limit against runaway recursion.
- The `Value` data model with `Object`, `List` and `Map`, plus `from_json` and `value_destroy`.
- Tests generated from the official specification suites, and examples under `examples/basic` and `examples/json`.

[Unreleased]: https://github.com/alexisbcz/odin-mustache/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/alexisbcz/odin-mustache/releases/tag/v0.1.0
