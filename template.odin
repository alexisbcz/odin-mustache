package mustache

import "base:runtime"
import "core:strings"

/*
Template is a compiled Mustache template: an abstract syntax tree that render
walks without parsing again.

Create one with compile and free it with template_destroy. The template owns a
copy of its source, so the string passed to compile may be freed right after
the call. Rendering only reads the template, so one Template may be rendered
from several threads at once.
*/
Template :: struct {
	// The top-level nodes in source order.
	nodes:     []Node,
	// The template's own copy of the source; Text nodes and names point into it.
	source:    string,
	// The allocator that owns nodes, names and source.
	allocator: runtime.Allocator,
}

// Node is one element of a compiled template.
Node :: union {
	Text,
	Variable,
	Section,
	Partial,
}

// Text is literal template text, written out unchanged.
Text :: struct {
	text: string,
}

/*
Name is a dotted name split into its parts, so `{{a.b.c}}` becomes
`{"a", "b", "c"}`. An empty Name is the implicit iterator `{{.}}`, which
refers to the current context.
*/
Name :: []string

// Variable is an interpolation tag: `{{name}}`, or `{{{name}}}` and `{{&name}}` when unescaped.
Variable :: struct {
	name:   Name,
	// The text of the tag name as written, for diagnostics.
	key:    string,
	// True for `{{name}}`, which escapes HTML; false for `{{{name}}}` and `{{&name}}`.
	escape: bool,
}

/*
Section is a `{{#name}}` or `{{^name}}` block. A section renders its children
once for a truthy value, once per element for a non-empty List, and never for
false, null, a missing name or an empty List. An inverted section renders its
children exactly when a normal section would not.
*/
Section :: struct {
	name:             Name,
	// The text of the tag name as written, for diagnostics.
	key:              string,
	// True for `{{^name}}`.
	inverted:         bool,
	// The nodes between the opening and closing tags.
	children:         []Node,
	// The opening tag stood alone on its line, so compile removed that line.
	standalone_open:  bool,
	// The closing tag stood alone on its line, so compile removed that line.
	standalone_close: bool,
}

/*
Partial is a `{{> name}}` tag. When the tag stands alone on its line, render
prefixes every line of the included template with `indent`.
*/
Partial :: struct {
	// The partial's name, or for a dynamic partial the dotted name as written.
	key:        string,
	// For a dynamic partial `{{>*name}}`, the name to resolve in the context.
	name:       Name,
	// True for `{{>*name}}`, whose partial name comes from the data.
	is_dynamic: bool,
	// The whitespace before a standalone tag; empty otherwise.
	indent:     string,
	// The tag stood alone on its line, so compile removed that line.
	standalone: bool,
}

/*
compile parses `source` into a Template.

Inputs:
- source: the template text; compile copies it, so the caller keeps ownership.
- allocator: allocates every part of the template.

Returns:
- tmpl: the compiled template; free it with template_destroy.
- err: a Parse_Error or an allocator error. On error, tmpl is zero and nothing leaks.
*/
compile :: proc(source: string, allocator := context.allocator) -> (tmpl: Template, err: Error) {
	tmpl, _, err = compile_with_location(source, allocator)
	return
}

/*
compile_with_location works like compile and also says where a parse error
starts.

Inputs:
- source: the template text; compile_with_location copies it, so the caller keeps ownership.
- allocator: allocates every part of the template.

Returns:
- tmpl: the compiled template; free it with template_destroy.
- loc: on a Parse_Error, the position of the tag at fault; zero otherwise.
- err: a Parse_Error or an allocator error. On error, tmpl is zero and nothing leaks.
*/
compile_with_location :: proc(source: string, allocator := context.allocator) -> (tmpl: Template, loc: Location, err: Error) {
	src := strings.clone(source, allocator) or_return

	p := Parser {
		src       = src,
		otag      = "{{",
		ctag      = "}}",
		allocator = allocator,
	}
	p.frames.allocator = allocator

	nodes, error_offset, perr := parse(&p)
	if perr != nil {
		for &f in p.frames {
			destroy_nodes(f.nodes[:], allocator)
			delete(f.nodes)
			delete(f.name, allocator)
		}
		delete(p.frames)
		delete(src, allocator)
		if _, is_parse := perr.(Parse_Error); is_parse {
			loc = location_of(source, error_offset)
		}
		return {}, loc, perr
	}
	delete(p.frames)
	return Template{nodes = nodes, source = src, allocator = allocator}, {}, nil
}

/*
template_destroy frees everything that `tmpl` owns and zeroes it. Calling it on
a zero Template is safe.
*/
template_destroy :: proc(tmpl: ^Template) {
	if tmpl == nil {
		return
	}
	destroy_nodes(tmpl.nodes, tmpl.allocator)
	delete(tmpl.nodes, tmpl.allocator)
	delete(tmpl.source, tmpl.allocator)
	tmpl^ = {}
}

@(private)
destroy_nodes :: proc(nodes: []Node, allocator: runtime.Allocator) {
	for &node in nodes {
		switch &n in node {
		case Text:
		case Variable:
			delete(n.name, allocator)
		case Section:
			delete(n.name, allocator)
			destroy_nodes(n.children, allocator)
			delete(n.children, allocator)
		case Partial:
			delete(n.name, allocator)
		}
	}
}

// A section that is open while parsing. Frame 0 holds the top-level nodes.
@(private)
Frame :: struct {
	nodes:           [dynamic]Node,
	name:            Name,
	key:             string,
	inverted:        bool,
	standalone_open: bool,
	// Offset of the opening tag, for Unclosed_Section.
	offset:          int,
}

@(private)
Parser :: struct {
	src:       string,
	otag:      string,
	ctag:      string,
	frames:    [dynamic]Frame,
	allocator: runtime.Allocator,
}

@(private)
Tag_Kind :: enum {
	Variable,
	Unescaped,
	Triple,
	Section,
	Inverted,
	Close,
	Comment,
	Partial,
	Delimiters,
	Unsupported,
}

// parse fills p.frames while it scans. On success it returns the top-level nodes and leaves no frames.
@(private)
parse :: proc(p: ^Parser) -> (nodes: []Node, error_offset: int, err: Error) {
	src := p.src
	append(&p.frames, Frame{nodes = make([dynamic]Node, p.allocator)}) or_return

	pos, text_start := 0, 0
	for {
		idx := strings.index(src[pos:], p.otag)
		if idx < 0 {
			push_text(p, src[text_start:]) or_return
			break
		}
		tag_start := pos + idx
		// Errors returned through or_return below point at this tag.
		error_offset = tag_start
		after_open := tag_start + len(p.otag)
		if after_open >= len(src) {
			return nil, tag_start, .Unclosed_Tag
		}

		kind := Tag_Kind.Variable
		content_start := after_open + 1
		switch src[after_open] {
		case '#':
			kind = .Section
		case '^':
			kind = .Inverted
		case '/':
			kind = .Close
		case '!':
			kind = .Comment
		case '>':
			kind = .Partial
		case '=':
			kind = .Delimiters
		case '&':
			kind = .Unescaped
		case '{':
			kind = .Triple
		case '$', '<':
			kind = .Unsupported
		case:
			content_start = after_open
		}

		// Find the end of the tag. Triple and set delimiter tags end with an extra character.
		close_idx, tag_end := -1, -1
		switch kind {
		case .Triple:
			close_idx = index_before(src, content_start, '}', p.ctag)
			tag_end = close_idx + 1 + len(p.ctag)
		case .Delimiters:
			close_idx = index_before(src, content_start, '=', p.ctag)
			tag_end = close_idx + 1 + len(p.ctag)
		case .Variable, .Unescaped, .Section, .Inverted, .Close, .Comment, .Partial, .Unsupported:
			if i := strings.index(src[content_start:], p.ctag); i >= 0 {
				close_idx = content_start + i
				tag_end = close_idx + len(p.ctag)
			}
		}
		if close_idx < 0 {
			return nil, tag_start, .Unclosed_Tag
		}
		if kind == .Unsupported {
			return nil, tag_start, .Unsupported_Tag
		}
		content := strings.trim_space(src[content_start:close_idx])

		// A tag other than an interpolation stands alone when only spaces and
		// tabs share its line. Compile then drops the whole line, newline included.
		text_end, next := tag_start, tag_end
		standalone := false
		indent := ""
		#partial switch kind {
		case .Section, .Inverted, .Close, .Comment, .Partial, .Delimiters:
			line_start := tag_start
			for line_start > text_start && is_blank(src[line_start - 1]) {
				line_start -= 1
			}
			if line_start == 0 || src[line_start - 1] == '\n' {
				e := tag_end
				for e < len(src) && is_blank(src[e]) {
					e += 1
				}
				switch {
				case e == len(src):
					standalone, next = true, e
				case src[e] == '\n':
					standalone, next = true, e + 1
				case src[e] == '\r' && e + 1 < len(src) && src[e + 1] == '\n':
					standalone, next = true, e + 2
				}
			}
			if standalone {
				text_end = line_start
				indent = src[line_start:tag_start]
			}
		}
		push_text(p, src[text_start:text_end]) or_return

		switch kind {
		case .Variable, .Unescaped, .Triple:
			name := parse_name(content, p.allocator) or_return
			top := &p.frames[len(p.frames) - 1]
			if _, aerr := append(&top.nodes, Variable{name = name, key = content, escape = kind == .Variable}); aerr != nil {
				delete(name, p.allocator)
				return nil, tag_start, aerr
			}

		case .Section, .Inverted:
			// Frame 0 holds the top level, so len(p.frames) is the depth of the new section.
			if len(p.frames) > MAX_NESTING_DEPTH {
				return nil, tag_start, .Too_Deeply_Nested
			}
			name := parse_name(content, p.allocator) or_return
			frame := Frame {
				name            = name,
				key             = content,
				inverted        = kind == .Inverted,
				standalone_open = standalone,
				offset          = tag_start,
			}
			frame.nodes.allocator = p.allocator
			if _, aerr := append(&p.frames, frame); aerr != nil {
				delete(name, p.allocator)
				return nil, tag_start, aerr
			}

		case .Close:
			if content == "" {
				return nil, tag_start, .Empty_Tag
			}
			if len(p.frames) == 1 {
				return nil, tag_start, .Unexpected_Close
			}
			top := p.frames[len(p.frames) - 1]
			if top.key != content {
				return nil, tag_start, .Mismatched_Close
			}
			section := Section {
				name             = top.name,
				key              = top.key,
				inverted         = top.inverted,
				children         = top.nodes[:],
				standalone_open  = top.standalone_open,
				standalone_close = standalone,
			}
			parent := &p.frames[len(p.frames) - 2]
			append(&parent.nodes, section) or_return
			pop(&p.frames)

		case .Comment:

		case .Partial:
			if content == "" {
				return nil, tag_start, .Empty_Tag
			}
			partial := Partial {
				key        = content,
				indent     = indent,
				standalone = standalone,
			}
			if content[0] == '*' {
				partial.is_dynamic = true
				partial.key = strings.trim_space(content[1:])
				partial.name = parse_name(partial.key, p.allocator) or_return
				if len(partial.name) == 0 {
					// `{{>*.}}` has no name to resolve.
					return nil, tag_start, .Invalid_Name
				}
			}
			top := &p.frames[len(p.frames) - 1]
			if _, aerr := append(&top.nodes, partial); aerr != nil {
				delete(partial.name, p.allocator)
				return nil, tag_start, aerr
			}

		case .Delimiters:
			otag, ctag, ok := split_delimiters(content)
			if !ok {
				return nil, tag_start, .Invalid_Delimiters
			}
			p.otag, p.ctag = otag, ctag

		case .Unsupported:
			unreachable()
		}

		pos, text_start = next, next
	}

	if len(p.frames) > 1 {
		return nil, p.frames[len(p.frames) - 1].offset, .Unclosed_Section
	}
	root := pop(&p.frames)
	return root.nodes[:], 0, nil
}

@(private)
push_text :: proc(p: ^Parser, text: string) -> runtime.Allocator_Error {
	if len(text) == 0 {
		return nil
	}
	top := &p.frames[len(p.frames) - 1]
	_, err := append(&top.nodes, Text{text = text})
	return err
}

// parse_name splits a trimmed tag name on dots. "." is the implicit iterator and yields an empty Name.
@(private)
parse_name :: proc(content: string, allocator: runtime.Allocator) -> (name: Name, err: Error) {
	if content == "" {
		return nil, Parse_Error.Empty_Tag
	}
	if content == "." {
		return nil, nil
	}
	parts := 1
	for i in 0 ..< len(content) {
		switch content[i] {
		case ' ', '\t', '\n', '\r', '\v', '\f':
			return nil, Parse_Error.Invalid_Name
		case '.':
			parts += 1
		}
	}
	name = make(Name, parts, allocator) or_return
	rest := content
	for i in 0 ..< parts {
		dot := strings.index_byte(rest, '.')
		part := rest if dot < 0 else rest[:dot]
		if part == "" {
			delete(name, allocator)
			return nil, Parse_Error.Invalid_Name
		}
		name[i] = part
		rest = rest[dot + 1:] if dot >= 0 else ""
	}
	return name, nil
}

// split_delimiters reads "open close" from a set delimiter tag.
@(private)
split_delimiters :: proc(content: string) -> (otag, ctag: string, ok: bool) {
	i := 0
	for i < len(content) && !is_space(content[i]) {
		i += 1
	}
	otag = content[:i]
	ctag = strings.trim_space(content[i:])
	if otag == "" || ctag == "" {
		return "", "", false
	}
	for j in 0 ..< len(ctag) {
		if is_space(ctag[j]) {
			return "", "", false
		}
	}
	if strings.contains_rune(otag, '=') || strings.contains_rune(ctag, '=') {
		return "", "", false
	}
	return otag, ctag, true
}

// index_before finds the first `c` at or after `from` that `ctag` follows directly, and returns its index or -1.
@(private)
index_before :: proc(src: string, from: int, c: byte, ctag: string) -> int {
	for i := from; i < len(src); i += 1 {
		if src[i] == c && strings.has_prefix(src[i + 1:], ctag) {
			return i
		}
	}
	return -1
}

@(private)
is_blank :: #force_inline proc "contextless" (c: byte) -> bool {
	return c == ' ' || c == '\t'
}

@(private)
is_space :: #force_inline proc "contextless" (c: byte) -> bool {
	return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' || c == '\f'
}

@(private)
location_of :: proc(src: string, offset: int) -> Location {
	loc := Location{offset = offset, line = 1, column = 1}
	for i in 0 ..< min(offset, len(src)) {
		if src[i] == '\n' {
			loc.line += 1
			loc.column = 1
		} else {
			loc.column += 1
		}
	}
	return loc
}
