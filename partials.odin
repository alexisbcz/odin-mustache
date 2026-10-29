package mustache

import "base:runtime"
import "core:strings"

/*
Partials is a named set of compiled templates that `{{> name}}` tags include.

Create one with partials_init, fill it with partials_add or
partials_add_template, and release it with partials_destroy. A zero Partials
is also ready to use: like an Odin map, it adopts `context.allocator` the first
time something is added to it. A name with no
partial renders as empty text, as the Mustache specification requires.
Rendering only reads a Partials value, so several threads may share one while
nothing adds to it.
*/
Partials :: struct {
	// Compiled partials by name. The keys and templates belong to the Partials value.
	templates: map[string]Template,
	// Allocates keys, the map and the templates that partials_add compiles.
	allocator: runtime.Allocator,
}

/*
partials_init prepares `p` for use. Every allocation it makes later, including
compiled templates and copies of names, uses `allocator`. Call partials_destroy
when done.
*/
partials_init :: proc(p: ^Partials, allocator := context.allocator) {
	p.allocator = allocator
	p.templates = make(map[string]Template, allocator)
}

// partials_destroy frees every name, every template and the map itself. The value is zeroed.
partials_destroy :: proc(p: ^Partials) {
	for name, &tmpl in p.templates {
		delete(name, p.allocator)
		template_destroy(&tmpl)
	}
	delete(p.templates)
	p^ = {}
}

/*
partials_add compiles `source` and stores it under `name`, replacing and
freeing any partial already stored under that name. It copies both strings.

Returns:
- err: a Parse_Error or an allocator error. On error, `p` is unchanged.
  Use compile_with_location and partials_add_template when you need the position of a parse error.
*/
partials_add :: proc(p: ^Partials, name, source: string) -> (err: Error) {
	adopt_context_allocator(p)
	tmpl := compile(source, p.allocator) or_return
	return partials_add_template(p, name, tmpl)
}

/*
partials_add_template stores an already compiled template under `name`,
replacing and freeing any partial already stored under that name.

The Partials value takes ownership of `tmpl`, even when this procedure fails,
so don't call template_destroy on it afterwards. It copies `name`.

Returns:
- err: an allocator error. On error, `tmpl` is destroyed and `p` is unchanged.
*/
partials_add_template :: proc(p: ^Partials, name: string, tmpl: Template) -> (err: Error) {
	adopt_context_allocator(p)
	tmpl := tmpl
	if existing, found := &p.templates[name]; found {
		template_destroy(existing)
		existing^ = tmpl
		return nil
	}
	key, cerr := strings.clone(name, p.allocator)
	if cerr != nil {
		template_destroy(&tmpl)
		return cerr
	}
	if rerr := reserve(&p.templates, len(p.templates) + 1); rerr != nil {
		delete(key, p.allocator)
		template_destroy(&tmpl)
		return rerr
	}
	p.templates[key] = tmpl
	return nil
}

// adopt_context_allocator gives a zero Partials the context allocator, so that it never copies names with a nil allocator.
@(private)
adopt_context_allocator :: proc(p: ^Partials) {
	if p.allocator.procedure == nil {
		p.allocator = context.allocator
		p.templates.allocator = context.allocator
	}
}
