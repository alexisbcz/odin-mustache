// Package mustache_tests holds the unit tests for mustache. Run them with `odin test tests`.
package mustache_tests

import mustache ".."
import "core:encoding/json"
import "core:mem"
import "core:testing"

/*
Leak_Tracker wraps one test in its own tracking allocator. Every test starts
with `context.allocator = track_leaks(t).allocator`; when the test returns,
expect_no_leaks fails it on any leaked allocation or bad free.
*/
Leak_Tracker :: struct {
	t:         ^testing.T,
	tracking:  ^mem.Tracking_Allocator,
	allocator: mem.Allocator,
	backing:   mem.Allocator,
}

@(deferred_out = expect_no_leaks)
track_leaks :: proc(t: ^testing.T) -> Leak_Tracker {
	tracking := new(mem.Tracking_Allocator)
	mem.tracking_allocator_init(tracking, context.allocator)
	return {t = t, tracking = tracking, allocator = mem.tracking_allocator(tracking), backing = context.allocator}
}

expect_no_leaks :: proc(lt: Leak_Tracker) {
	for _, entry in lt.tracking.allocation_map {
		testing.expectf(lt.t, false, "leaked %v bytes allocated at %v", entry.size, entry.location)
	}
	for bad in lt.tracking.bad_free_array {
		testing.expectf(lt.t, false, "bad free of %p at %v", bad.memory, bad.location)
	}
	mem.tracking_allocator_destroy(lt.tracking)
	free(lt.tracking, lt.backing)
}

// expect_render compiles `source`, renders it with `data` and compares the output.
expect_render :: proc(t: ^testing.T, source: string, data: mustache.Value, expected: string, partials: ^mustache.Partials = nil, loc := #caller_location) {
	tmpl, err := mustache.compile(source)
	if !testing.expectf(t, err == nil, "compile %q failed: %v", source, err, loc = loc) {
		return
	}
	defer mustache.template_destroy(&tmpl)
	out, rerr := mustache.render(tmpl, data, partials)
	defer delete(out)
	testing.expectf(t, rerr == nil, "render %q failed: %v", source, rerr, loc = loc)
	testing.expectf(t, out == expected, "render %q: got %q, want %q", source, out, expected, loc = loc)
}

// expect_compile_error checks that `source` fails to compile with `want`.
expect_compile_error :: proc(t: ^testing.T, source: string, want: mustache.Parse_Error, loc := #caller_location) {
	tmpl, err := mustache.compile(source)
	defer mustache.template_destroy(&tmpl)
	testing.expectf(t, err == mustache.Error(want), "compile %q: got %v, want %v", source, err, want, loc = loc)
	testing.expectf(t, tmpl.nodes == nil && tmpl.source == "", "compile %q returned a non-zero template on error", source, loc = loc)
}

// Spec_Partial is one entry of a spec case's partials table.
Spec_Partial :: struct {
	name:   string,
	source: string,
}

// Spec_Case is one test from the Mustache specification, with its data as JSON text.
Spec_Case :: struct {
	name:     string,
	template: string,
	data:     string,
	partials: []Spec_Partial,
	expected: string,
}

/*
run_spec_case renders one spec case twice: once through render_json on the
parsed JSON, with integers kept as i64, and once through render on a from_json
copy, with every number as f64. Both must match the expected output exactly.
*/
run_spec_case :: proc(t: ^testing.T, c: Spec_Case) {
	context.allocator = track_leaks(t).allocator

	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	for p in c.partials {
		err := mustache.partials_add(&partials, p.name, p.source)
		if !testing.expectf(t, err == nil, "%s: partial %q failed to compile: %v", c.name, p.name, err) {
			return
		}
	}

	tmpl, err := mustache.compile(c.template)
	if !testing.expectf(t, err == nil, "%s: template failed to compile: %v", c.name, err) {
		return
	}
	defer mustache.template_destroy(&tmpl)

	{
		data, jerr := json.parse_string(c.data, .JSON, parse_integers = true)
		defer json.destroy_value(data)
		if !testing.expectf(t, jerr == nil, "%s: bad JSON data: %v", c.name, jerr) {
			return
		}
		out, rerr := mustache.render_json(tmpl, data, &partials)
		defer delete(out)
		testing.expectf(t, rerr == nil, "%s (json): render failed: %v", c.name, rerr)
		testing.expectf(t, out == c.expected, "%s (json):\n got %q\nwant %q", c.name, out, c.expected)
	}

	{
		raw, jerr := json.parse_string(c.data, .JSON, parse_integers = false)
		defer json.destroy_value(raw)
		if !testing.expectf(t, jerr == nil, "%s: bad JSON data: %v", c.name, jerr) {
			return
		}
		data, cerr := mustache.from_json(raw)
		defer mustache.value_destroy(data)
		testing.expectf(t, cerr == nil, "%s: from_json failed: %v", c.name, cerr)
		out, rerr := mustache.render(tmpl, data, &partials)
		defer delete(out)
		testing.expectf(t, rerr == nil, "%s (value): render failed: %v", c.name, rerr)
		testing.expectf(t, out == c.expected, "%s (value):\n got %q\nwant %q", c.name, out, c.expected)
	}
}

/*
Failing_Allocator passes requests to `backing` until `remaining` allocations
have succeeded, then fails every later allocation and resize with
Out_Of_Memory. Frees always reach `backing`.
*/
Failing_Allocator :: struct {
	backing:   mem.Allocator,
	remaining: int,
}

failing_allocator :: proc(fa: ^Failing_Allocator) -> mem.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

failing_allocator_proc :: proc(
	data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.remaining <= 0 {
			return nil, .Out_Of_Memory
		}
		fa.remaining -= 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}
