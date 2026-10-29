/*
Package mustache renders logic-less Mustache templates.

It implements the Mustache specification v1.4: escaped and unescaped
variables, dotted names, the implicit iterator, sections, inverted sections,
comments, partials, dynamic partial names, set delimiters and standalone line
handling. Lambdas and template inheritance are not supported; parent and block
tags (`{{< name}}` and `{{$ name}}`) fail to compile with `.Unsupported_Tag`.

Compile a template once with compile, then render it as often as you like with
render (for Value data) or render_json (for core:encoding/json values). A
compiled Template is read-only while rendering, so several threads may render
the same Template, and the same Partials, at once.

Example:
	import "core:fmt"
	import "shared:mustache"

	main :: proc() {
		tmpl, err := mustache.compile("Hello, {{name}}.")
		if err != nil {
			return
		}
		defer mustache.template_destroy(&tmpl)

		data := mustache.Object{{"name", "world"}}
		out, rerr := mustache.render(tmpl, data)
		if rerr != nil {
			return
		}
		defer delete(out)
		fmt.println(out) // Hello, world.
	}
*/
package mustache

import "base:runtime"
import "core:encoding/json"
import "core:io"
import "core:strings"

/*
Parse_Error lists the ways a template source can fail to compile.
compile_with_location reports where the problem starts.
*/
Parse_Error :: enum {
	None,
	// An opening delimiter has no matching closing delimiter.
	Unclosed_Tag,
	// A tag has no name, as in `{{}}` or `{{#}}`.
	Empty_Tag,
	// A tag name contains whitespace or an empty dotted segment, as in `{{a..b}}`.
	Invalid_Name,
	// A set delimiter tag is not of the form `{{=open close=}}`.
	Invalid_Delimiters,
	// A section or inverted section is still open at the end of the template.
	Unclosed_Section,
	// A closing tag appears without an open section.
	Unexpected_Close,
	// A closing tag names a different section than the one that is open.
	Mismatched_Close,
	// The tag uses an optional spec module that this package doesn't implement.
	Unsupported_Tag,
}

// Render_Error lists the ways rendering a valid template can fail.
Render_Error :: enum {
	None,
	// Partials nested deeper than MAX_PARTIAL_DEPTH, usually through unbounded recursion.
	Partial_Depth_Exceeded,
}

/*
Error is the compound error type returned by every fallible procedure in this
package. `nil` means success. Compare it against a specific variant, such as
`mustache.Parse_Error.Unclosed_Tag`, or use a type switch.
*/
Error :: union #shared_nil {
	Parse_Error,
	Render_Error,
	io.Error,
	runtime.Allocator_Error,
}

/*
Location points at a byte in a template source. compile_with_location returns
it next to a Parse_Error.
*/
Location :: struct {
	// Byte offset from the start of the source.
	offset: int,
	// Line number, starting at 1.
	line:   int,
	// Column in bytes, starting at 1.
	column: int,
}

// MAX_PARTIAL_DEPTH bounds how deeply partials may include other partials.
MAX_PARTIAL_DEPTH :: 128

/*
Value is the dynamic data type that templates read from.

- `nil` is null and renders as empty text.
- `bool`, `i64`, `f64` and `string` render as text.
- List is a sequence; a section repeats once per element.
- Object is an ordered list of key and value pairs, convenient for literals.
- Map is a hash map, convenient for large or generated data.

A Value doesn't own memory by itself. Values that from_json returns are fully
heap allocated; free them with value_destroy.
*/
Value :: union {
	bool,
	i64,
	f64,
	string,
	List,
	Object,
	Map,
}

// List is a sequence of values. A section over a non-empty List renders once per element.
List :: distinct []Value

/*
Object is a sequence of fields, searched in order, so the first field with a
matching key wins. Because it is a slice, you can write it as a literal that
needs no heap allocation:

	data := mustache.Object{{"name", "Chris"}, {"admin", true}}
*/
Object :: distinct []Field

// Field is one key and value pair of an Object.
Field :: struct {
	key:   string,
	value: Value,
}

// Map is a hash map from keys to values. from_json builds JSON objects as Maps.
Map :: distinct map[string]Value

/*
render renders `tmpl` with `data` as the root context.

Inputs:
- tmpl: a compiled template.
- data: the root context.
- partials: templates that `{{> name}}` tags can include; nil means none.
- allocator: allocates the result and scratch memory, which it frees before returning.

Returns:
- output: the rendered text, owned by the caller; free it with `delete(output, allocator)`.
- err: `.Partial_Depth_Exceeded`, an io.Error or an allocator error. On error, output is empty.
*/
render :: proc(tmpl: Template, data: Value, partials: ^Partials = nil, allocator := context.allocator) -> (output: string, err: Error) {
	return render_ref(tmpl, data, partials, allocator)
}

/*
render_json renders `tmpl` with a core:encoding/json value as the root context.
It reads the JSON tree in place and doesn't copy it.

Inputs:
- tmpl: a compiled template.
- data: the root context, for example the result of json.parse.
- partials: templates that `{{> name}}` tags can include; nil means none.
- allocator: allocates the result and scratch memory, which it frees before returning.

Returns:
- output: the rendered text, owned by the caller; free it with `delete(output, allocator)`.
- err: `.Partial_Depth_Exceeded`, an io.Error or an allocator error. On error, output is empty.
*/
render_json :: proc(tmpl: Template, data: json.Value, partials: ^Partials = nil, allocator := context.allocator) -> (output: string, err: Error) {
	return render_ref(tmpl, data, partials, allocator)
}

/*
render_to_writer renders `tmpl` with `data` and writes the text to `w`.
It writes as it goes, so `w` may hold partial output when it returns an error.

Inputs:
- w: the destination.
- tmpl: a compiled template.
- data: the root context.
- partials: templates that `{{> name}}` tags can include; nil means none.
- allocator: allocates scratch memory, which it frees before returning.

Returns:
- err: `.Partial_Depth_Exceeded`, an error from `w`, or an allocator error.
*/
render_to_writer :: proc(w: io.Writer, tmpl: Template, data: Value, partials: ^Partials = nil, allocator := context.allocator) -> Error {
	return render_ref_to_writer(w, tmpl, data, partials, allocator)
}

/*
render_json_to_writer renders `tmpl` with a core:encoding/json value and writes
the text to `w`. It writes as it goes, so `w` may hold partial output when it
returns an error.

Inputs:
- w: the destination.
- tmpl: a compiled template.
- data: the root context.
- partials: templates that `{{> name}}` tags can include; nil means none.
- allocator: allocates scratch memory, which it frees before returning.

Returns:
- err: `.Partial_Depth_Exceeded`, an error from `w`, or an allocator error.
*/
render_json_to_writer :: proc(w: io.Writer, tmpl: Template, data: json.Value, partials: ^Partials = nil, allocator := context.allocator) -> Error {
	return render_ref_to_writer(w, tmpl, data, partials, allocator)
}

/*
render_string compiles `source`, renders it once with `data` and frees the
compiled template. Prefer compile and render when you render a template more
than once.

Inputs:
- source: the template text.
- data: the root context.
- partials: templates that `{{> name}}` tags can include; nil means none.
- allocator: allocates the result and scratch memory, which it frees before returning.

Returns:
- output: the rendered text, owned by the caller; free it with `delete(output, allocator)`.
- err: a Parse_Error, a Render_Error, an io.Error or an allocator error.
*/
render_string :: proc(source: string, data: Value, partials: ^Partials = nil, allocator := context.allocator) -> (output: string, err: Error) {
	tmpl := compile(source, allocator) or_return
	defer template_destroy(&tmpl)
	return render(tmpl, data, partials, allocator)
}

@(private)
render_ref :: proc(tmpl: Template, data: Ref, partials: ^Partials, allocator: runtime.Allocator) -> (output: string, err: Error) {
	b := strings.builder_make(allocator) or_return
	if err = render_ref_to_writer(strings.to_writer(&b), tmpl, data, partials, allocator); err != nil {
		strings.builder_destroy(&b)
		return "", err
	}
	return strings.to_string(b), nil
}
