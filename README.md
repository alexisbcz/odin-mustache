# mustache

[![CI](https://github.com/alexisbcz/odin-mustache/actions/workflows/ci.yml/badge.svg)](https://github.com/alexisbcz/odin-mustache/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Odin](https://img.shields.io/badge/Odin-dev--2026--09-1e5a99.svg)](https://odin-lang.org)

Logic-less [Mustache](https://mustache.github.io) templates for Odin: compile a template once, then render it with literal data or with `core:encoding/json` values, without leaks and without panics.

- Implements the Mustache specification v1.4.3: escaped and unescaped variables, dotted names, sections, inverted sections, comments, partials, dynamic partial names, set delimiters and standalone lines.
- Passes all 157 cases of the official comments, delimiters, interpolation, inverted, partials, sections and dynamic names suites.
- Compiles templates to an abstract syntax tree that you can render many times, from several threads at once.
- Takes an explicit allocator everywhere and reports malformed templates as errors with a line and column.

## Install

The repository root is the package, so you can vendor it in two ways.

As a Git submodule inside your project:

```sh
git submodule add https://github.com/alexisbcz/odin-mustache libs/mustache
```

```odin
import "libs/mustache"
```

As a copy in a shared collection that all your projects use:

```sh
git clone https://github.com/alexisbcz/odin-mustache ~/odin-shared/mustache
odin build . -collection:shared=$HOME/odin-shared
```

```odin
import "shared:mustache"
```

Odin names an import after its directory, so clone into a directory called `mustache` as shown. If you keep the `odin-mustache` name, give the import a name: `import mustache "shared:odin-mustache"`.

## Quick start

```odin
package main

import "core:fmt"
import "shared:mustache"

main :: proc() {
	tmpl, err := mustache.compile("Hello {{name}}. You have {{count}} new {{#one}}message{{/one}}{{^one}}messages{{/one}}.")
	if err != nil {
		fmt.eprintln("compile failed:", err)
		return
	}
	defer mustache.template_destroy(&tmpl)

	data := mustache.Object{{"name", "Ada"}, {"count", i64(3)}, {"one", false}}
	out, rerr := mustache.render(tmpl, data)
	if rerr != nil {
		fmt.eprintln("render failed:", rerr)
		return
	}
	defer delete(out)
	fmt.println(out) // Hello Ada. You have 3 new messages.
}
```

An `Object` is a slice of key and value pairs, so the literal above lives on the stack and needs no cleanup. Write integers as `i64(3)`, because an untyped constant could be either an `i64` or an `f64`.

## Rendering JSON

`render_json` reads a `json.Value` in place. It doesn't copy the tree.

```odin
package main

import "core:encoding/json"
import "core:fmt"
import "shared:mustache"

main :: proc() {
	data, jerr := json.parse_string(`{"user": {"name": "Ada"}, "tags": ["odin", "c"]}`, parse_integers = true)
	if jerr != nil {
		return
	}
	defer json.destroy_value(data)

	tmpl, err := mustache.compile("{{user.name}}:{{#tags}} #{{.}}{{/tags}}")
	if err != nil {
		return
	}
	defer mustache.template_destroy(&tmpl)

	out, rerr := mustache.render_json(tmpl, data)
	if rerr != nil {
		return
	}
	defer delete(out)
	fmt.println(out) // Ada: #odin #c
}
```

To keep or extend JSON data as a `Value`, copy it with `from_json` and free the copy with `value_destroy`.

## Partials and errors

A `Partials` value holds compiled templates that `{{> name}}` tags include. When a partial tag stands alone on its line, every line of the partial gets the tag's indentation. `compile_with_location` says where a malformed template goes wrong.

```odin
package main

import "core:fmt"
import "shared:mustache"

main :: proc() {
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	if err := mustache.partials_add(&partials, "item", "<li>{{.}}</li>\n"); err != nil {
		return
	}

	page, loc, err := mustache.compile_with_location("<ul>\n{{#items}}\n  {{> item}}\n{{/items}}\n</ul>\n")
	if err != nil {
		fmt.eprintfln("line %d, column %d: %v", loc.line, loc.column, err)
		return
	}
	defer mustache.template_destroy(&page)

	out, rerr := mustache.render(page, mustache.Object{{"items", mustache.List{"one", "two"}}}, &partials)
	if rerr != nil {
		return
	}
	defer delete(out)
	fmt.print(out)
	// <ul>
	//   <li>one</li>
	//   <li>two</li>
	// </ul>

	_, bad_loc, bad_err := mustache.compile_with_location("Hi\n{{#user}}{{name}}")
	fmt.println(bad_err, bad_loc.line, bad_loc.column) // Unclosed_Section 2 1
}
```

## Data model

| Value | Interpolates as | Section `{{#x}}` |
| --- | --- | --- |
| `nil`, missing name | empty text | skipped |
| `bool` | `true` or `false` | rendered once when `true` |
| `i64` | decimal digits | rendered once |
| `f64` | shortest form, like JavaScript: `1.21`, `100`, `1e+21` | rendered once |
| `string` | the text, HTML escaped unless unescaped | rendered once, even when empty |
| `List` | empty text | rendered once per element, skipped when empty |
| `Object`, `Map` | empty text | rendered once with the value as context |

JSON values follow the same rules: `null` acts as `nil`, arrays as `List` and objects as `Map`. Escaping replaces `&`, `<`, `>` and `"` with HTML entities, as the specification requires. Use `{{{name}}}` or `{{&name}}` for raw output.

A name resolves from the innermost context outwards. In a dotted name such as `{{a.b.c}}`, only `a` searches outwards; `b` and `c` must resolve inside `a`.

## API overview

| Declaration | Purpose | Allocates | Free with |
| --- | --- | --- | --- |
| `compile(source, allocator)` | Parse a template into a `Template` | Yes | `template_destroy` |
| `compile_with_location(source, allocator)` | Like `compile`, plus the `Location` of a parse error | Yes | `template_destroy` |
| `render(tmpl, data, partials, allocator)` | Render with `Value` data to a string | Yes | `delete` |
| `render_json(tmpl, data, partials, allocator)` | Render with a `json.Value` to a string | Yes | `delete` |
| `render_to_writer(w, tmpl, data, partials, allocator)` | Stream the output of `render` to an `io.Writer` | Scratch only | Not needed |
| `render_json_to_writer(w, tmpl, data, partials, allocator)` | Stream the output of `render_json` to an `io.Writer` | Scratch only | Not needed |
| `render_string(source, data, partials, allocator)` | Compile, render once and free the template | Yes | `delete` |
| `Partials`, `partials_init(p, allocator)` | A registry of named partials | Yes | `partials_destroy` |
| `partials_add(p, name, source)` | Compile and register a partial | Yes | `partials_destroy` |
| `partials_add_template(p, name, tmpl)` | Register a compiled template; `p` takes ownership | Yes | `partials_destroy` |
| `from_json(j, allocator)` | Deep copy a `json.Value` as a `Value` | Yes | `value_destroy` |
| `Value`, `Object`, `Field`, `List`, `Map` | The dynamic data model | Not by itself | Your choice |
| `Template`, `Node`, `Text`, `Variable`, `Section`, `Partial` | The compiled syntax tree, open for inspection | No | Not needed |
| `Error` | Union of `Parse_Error`, `Render_Error`, `io.Error` and `runtime.Allocator_Error` | No | Not needed |

## Examples

Each directory under `examples/` is a runnable program:

```sh
odin run examples/basic
odin run examples/json
```

## Design notes

- Every allocating procedure takes `allocator := context.allocator` and says who owns the result.
- Fallible procedures return `(T, Error)`. Malformed templates come back as a `Parse_Error`, and partials that include each other without end come back as `Render_Error.Partial_Depth_Exceeded` after `MAX_PARTIAL_DEPTH` levels.
- `compile` handles delimiters, comments and standalone lines up front, so rendering walks the tree without scanning text again.
- A missing partial renders as empty text, as the specification requires.
- Lambdas and template inheritance are optional parts of the specification and aren't supported. Parent and block tags fail to compile with `Parse_Error.Unsupported_Tag`.
- The package keeps no global mutable state. A `Template` and a `Partials` value are read-only while rendering, so several threads can render them at once.

## Testing

```sh
odin check . -vet -strict-style -disallow-do -no-entry-point
odin test tests -vet -strict-style -disallow-do
vale sync && vale *.md
```

Each test runs under its own tracking allocator and fails on any leak or bad free. Several tests fail every allocation in turn to prove that each error path frees its memory.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Commits follow Conventional Commits, and every change that users can see gets a line in [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
