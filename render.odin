package mustache

import "base:runtime"
import "core:encoding/json"
import "core:io"
import "core:math"
import "core:strconv"
import "core:strings"

// Ref is one entry of the context stack: a borrowed view of either data model.
@(private)
Ref :: union {
	Value,
	json.Value,
}

@(private)
Renderer :: struct {
	w:             io.Writer,
	partials:      ^Partials,
	// The context stack; the innermost context is last.
	stack:         [dynamic]Ref,
	// The indentation of every standalone partial being rendered, outermost first.
	indents:       [dynamic]string,
	/*
	The spec indents every line of a standalone partial before rendering it.
	While pending is true, indents[pending_from:] is still owed to the current
	line and goes out before the next piece of template output on it. After a
	newline in template text every indent is owed again. A standalone partial
	that starts in the middle of a line, after an included partial that didn't
	end in a newline, owes only its own indent.
	*/
	pending:       bool,
	pending_from:  int,
	// Partials being rendered, bounded by MAX_PARTIAL_DEPTH.
	depth:         int,
	// Sections and partials being rendered, bounded by MAX_NESTING_DEPTH.
	nesting:       int,
}

@(private)
render_ref_to_writer :: proc(w: io.Writer, tmpl: Template, data: Ref, partials: ^Partials, allocator: runtime.Allocator) -> Error {
	r := Renderer {
		w             = w,
		partials      = partials,
		pending       = true,
	}
	r.stack = make([dynamic]Ref, 0, 16, allocator) or_return
	defer delete(r.stack)
	r.indents.allocator = allocator
	defer delete(r.indents)

	append(&r.stack, data) or_return
	return render_nodes(&r, tmpl.nodes)
}

@(private)
render_nodes :: proc(r: ^Renderer, nodes: []Node) -> Error {
	for &node in nodes {
		switch &n in node {
		case Text:
			write_text(r, n.text) or_return
		case Variable:
			flush_indent(r) or_return
			if v, found := lookup(r, n.name); found {
				write_value(r, v, n.escape) or_return
			}
		case Section:
			render_section(r, &n) or_return
		case Partial:
			render_partial(r, &n) or_return
		}
	}
	return nil
}

/*
enter counts one more level of section or partial nesting. Rendering recurses
once per level, so the limit keeps the stack bounded even when recursive
partials each nest a few sections.
*/
@(private)
enter :: #force_inline proc(r: ^Renderer) -> Error {
	if r.nesting >= MAX_NESTING_DEPTH {
		return .Nesting_Depth_Exceeded
	}
	r.nesting += 1
	return nil
}

@(private)
render_section :: proc(r: ^Renderer, s: ^Section) -> Error {
	// A standalone tag's line is gone from the output, so it owes no indentation.
	if !s.standalone_open {
		flush_indent(r) or_return
	}

	v, found := lookup(r, s.name)
	truthy := found && is_truthy(v)
	enter(r) or_return
	defer r.nesting -= 1
	switch {
	case s.inverted:
		if !truthy {
			render_nodes(r, s.children) or_return
		}
	case !truthy:
	case is_list(v):
		for i in 0 ..< list_len(v) {
			append(&r.stack, list_at(v, i)) or_return
			render_nodes(r, s.children) or_return
			pop(&r.stack)
		}
	case:
		append(&r.stack, v) or_return
		render_nodes(r, s.children) or_return
		pop(&r.stack)
	}
	return nil
}

@(private)
render_partial :: proc(r: ^Renderer, p: ^Partial) -> Error {
	if !p.standalone {
		flush_indent(r) or_return
	}

	if r.partials == nil {
		return nil
	}
	name := p.key
	if p.is_dynamic {
		v, found := lookup(r, p.name)
		if !found {
			return nil
		}
		s, ok := as_string(v)
		if !ok {
			return nil
		}
		name = s
	}
	tmpl, ok := r.partials.templates[name]
	if !ok {
		return nil
	}
	if r.depth >= MAX_PARTIAL_DEPTH {
		return .Partial_Depth_Exceeded
	}
	enter(r) or_return
	defer r.nesting -= 1

	if p.standalone {
		if !r.pending {
			r.pending, r.pending_from = true, len(r.indents)
		}
		append(&r.indents, p.indent) or_return
	}
	r.depth += 1
	err := render_nodes(r, tmpl.nodes)
	r.depth -= 1
	if p.standalone {
		pop(&r.indents)
		r.pending_from = min(r.pending_from, len(r.indents))
	}
	return err
}

// write_text writes template text, indenting each line when inside standalone partials.
@(private)
write_text :: proc(r: ^Renderer, text: string) -> Error {
	if len(r.indents) == 0 {
		write(r, text) or_return
		r.pending = text[len(text) - 1] == '\n'
		r.pending_from = 0
		return nil
	}
	rest := text
	for len(rest) > 0 {
		flush_indent(r) or_return
		nl := strings.index_byte(rest, '\n')
		if nl < 0 {
			write(r, rest) or_return
			break
		}
		write(r, rest[:nl + 1]) or_return
		rest = rest[nl + 1:]
		r.pending, r.pending_from = true, 0
	}
	return nil
}

@(private)
flush_indent :: proc(r: ^Renderer) -> Error {
	if !r.pending {
		return nil
	}
	r.pending = false
	for indent in r.indents[r.pending_from:] {
		write(r, indent) or_return
	}
	return nil
}

@(private)
write :: #force_inline proc(r: ^Renderer, s: string) -> io.Error {
	_, err := io.write_string(r.w, s)
	return err
}

/*
lookup resolves a dotted name. The first part is searched from the innermost
context outwards; the other parts must then resolve inside that value alone.
*/
@(private)
lookup :: proc(r: ^Renderer, name: Name) -> (v: Ref, found: bool) {
	if len(name) == 0 {
		return r.stack[len(r.stack) - 1], true
	}
	#reverse for ctx in r.stack {
		if v, found = get_field(ctx, name[0]); found {
			break
		}
	}
	if !found {
		return nil, false
	}
	for part in name[1:] {
		if v, found = get_field(v, part); !found {
			return nil, false
		}
	}
	return v, true
}

@(private)
get_field :: proc(ref: Ref, key: string) -> (v: Ref, found: bool) {
	switch x in ref {
	case Value:
		#partial switch y in x {
		case Object:
			for f in y {
				if f.key == key {
					return f.value, true
				}
			}
		case Map:
			if val, ok := y[key]; ok {
				return val, true
			}
		}
	case json.Value:
		#partial switch y in x {
		case json.Object:
			if val, ok := y[key]; ok {
				return val, true
			}
		}
	}
	return nil, false
}

// is_truthy reports whether a section renders: false, null and empty lists do not.
@(private)
is_truthy :: proc(ref: Ref) -> bool {
	switch x in ref {
	case Value:
		switch y in x {
		case bool:
			return y
		case List:
			return len(y) > 0
		case i64, f64, string, Object, Map:
			return true
		}
		return false
	case json.Value:
		switch y in x {
		case json.Null:
			return false
		case bool:
			return y
		case json.Array:
			return len(y) > 0
		case i64, f64, string, json.Object:
			return true
		}
		return false
	}
	return false
}

@(private)
is_list :: proc(ref: Ref) -> bool {
	switch x in ref {
	case Value:
		_, ok := x.(List)
		return ok
	case json.Value:
		_, ok := x.(json.Array)
		return ok
	}
	return false
}

@(private)
list_len :: proc(ref: Ref) -> int {
	#partial switch x in ref {
	case Value:
		return len(x.(List) or_else nil)
	case json.Value:
		return len(x.(json.Array) or_else nil)
	}
	return 0
}

@(private)
list_at :: proc(ref: Ref, i: int) -> Ref {
	#partial switch x in ref {
	case Value:
		return x.(List)[i]
	case json.Value:
		return x.(json.Array)[i]
	}
	return nil
}

@(private)
as_string :: proc(ref: Ref) -> (s: string, ok: bool) {
	switch x in ref {
	case Value:
		s, ok = x.(string)
	case json.Value:
		s, ok = x.(string)
	}
	return
}

// write_value interpolates a scalar. Null, lists, objects and maps write nothing.
@(private)
write_value :: proc(r: ^Renderer, ref: Ref, escape: bool) -> Error {
	buf: [128]byte
	switch x in ref {
	case Value:
		switch y in x {
		case bool:
			return write(r, "true" if y else "false")
		case i64:
			return write(r, format_int(buf[:], y))
		case f64:
			return write(r, format_float(buf[:], y))
		case string:
			return write_string_value(r, y, escape)
		case List, Object, Map:
		}
	case json.Value:
		switch y in x {
		case bool:
			return write(r, "true" if y else "false")
		case i64:
			return write(r, format_int(buf[:], y))
		case f64:
			return write(r, format_float(buf[:], y))
		case string:
			return write_string_value(r, y, escape)
		case json.Null, json.Array, json.Object:
		}
	}
	return nil
}

@(private)
write_string_value :: proc(r: ^Renderer, s: string, escape: bool) -> Error {
	if !escape {
		return write(r, s)
	}
	start := 0
	for i in 0 ..< len(s) {
		entity: string
		switch s[i] {
		case '&':
			entity = "&amp;"
		case '<':
			entity = "&lt;"
		case '>':
			entity = "&gt;"
		case '"':
			entity = "&quot;"
		case:
			continue
		}
		write(r, s[start:i]) or_return
		write(r, entity) or_return
		start = i + 1
	}
	return write(r, s[start:])
}

@(private)
format_int :: proc(buf: []byte, i: i64) -> string {
	return strip_plus(strconv.write_int(buf, i, 10))
}

/*
format_float prints a float the way JavaScript's Number to string conversion
does, because Mustache data usually comes from JSON: integral values have no
fraction, and only very large or very small magnitudes use an exponent.
*/
@(private)
format_float :: proc(buf: []byte, f: f64) -> string {
	switch {
	case math.is_nan(f):
		return "NaN"
	case math.is_inf(f, 1):
		return "Infinity"
	case math.is_inf(f, -1):
		return "-Infinity"
	case f == 0:
		return "0"
	}
	a := abs(f)
	if a >= 1e-6 && a < 1e21 {
		return strip_plus(strconv.write_float(buf, f, 'f', -1, 64))
	}
	s := strip_plus(strconv.write_float(buf, f, 'g', -1, 64))
	// Write 1e-7 rather than 1e-07, as JavaScript does.
	e := strings.index_byte(s, 'e')
	if e < 0 || e + 2 >= len(s) || s[e + 2] != '0' {
		return s
	}
	n := copy(buf[:], s[:e + 2])
	digits := strings.trim_left(s[e + 2:], "0")
	n += copy(buf[n:], digits)
	return string(buf[:n])
}

@(private)
strip_plus :: #force_inline proc(s: string) -> string {
	return s[1:] if len(s) > 0 && s[0] == '+' else s
}
