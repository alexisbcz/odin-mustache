package mustache_tests

import mustache ".."
import "base:runtime"
import "core:encoding/json"
import "core:io"
import "core:math"
import "core:mem"
import "core:strings"
import "core:sync"
import "core:testing"
import "core:thread"

// ---- Compiling ----

@(test)
test_compile_empty_source_has_no_nodes :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("")
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(tmpl.nodes), 0)
	expect_render(t, "", nil, "")
}

@(test)
test_compile_plain_text_is_one_text_node :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("no tags here { } }}")
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, nil)
	if testing.expect_value(t, len(tmpl.nodes), 1) {
		text, ok := tmpl.nodes[0].(mustache.Text)
		testing.expect(t, ok)
		testing.expect_value(t, text.text, "no tags here { } }}")
	}
}

@(test)
test_compile_builds_nested_section_tree :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("{{#a}}x{{^b}}{{c.d}}{{/b}}{{/a}}")
	defer mustache.template_destroy(&tmpl)
	if !testing.expect_value(t, err, nil) || !testing.expect_value(t, len(tmpl.nodes), 1) {
		return
	}
	a, a_ok := tmpl.nodes[0].(mustache.Section)
	testing.expect(t, a_ok)
	testing.expect_value(t, a.key, "a")
	testing.expect(t, !a.inverted)
	if !testing.expect_value(t, len(a.children), 2) {
		return
	}
	b, b_ok := a.children[1].(mustache.Section)
	testing.expect(t, b_ok)
	testing.expect(t, b.inverted)
	if !testing.expect_value(t, len(b.children), 1) {
		return
	}
	v, v_ok := b.children[0].(mustache.Variable)
	testing.expect(t, v_ok)
	testing.expect(t, v.escape)
	if testing.expect_value(t, len(v.name), 2) {
		testing.expect_value(t, v.name[0], "c")
		testing.expect_value(t, v.name[1], "d")
	}
}

@(test)
test_compile_implicit_iterator_has_empty_name :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("{{{ . }}}")
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, nil)
	if testing.expect_value(t, len(tmpl.nodes), 1) {
		v := tmpl.nodes[0].(mustache.Variable)
		testing.expect_value(t, len(v.name), 0)
		testing.expect(t, !v.escape)
	}
}

@(test)
test_compile_records_standalone_partial_indent :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("a\n \t{{> item }}\r\nb")
	defer mustache.template_destroy(&tmpl)
	if !testing.expect_value(t, err, nil) || !testing.expect_value(t, len(tmpl.nodes), 3) {
		return
	}
	p, ok := tmpl.nodes[1].(mustache.Partial)
	testing.expect(t, ok)
	testing.expect(t, p.standalone)
	testing.expect_value(t, p.indent, " \t")
	testing.expect_value(t, p.key, "item")
	testing.expect_value(t, tmpl.nodes[2].(mustache.Text).text, "b")
}

@(test)
test_compile_copies_the_source :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	source := strings.clone("Hi {{name}}.")
	tmpl, err := mustache.compile(source)
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, nil)
	// Overwrite and free the caller's copy; the template must not notice.
	mem.set(raw_data(source), 'X', len(source))
	delete(source)

	out, rerr := mustache.render(tmpl, mustache.Object{{"name", "Ann"}})
	defer delete(out)
	testing.expect_value(t, rerr, nil)
	testing.expect_value(t, out, "Hi Ann.")
}

@(test)
test_template_destroy_is_safe_on_zero_and_twice :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	zero: mustache.Template
	mustache.template_destroy(&zero)
	mustache.template_destroy(nil)

	tmpl, err := mustache.compile("{{#a}}{{b}}{{/a}}")
	testing.expect_value(t, err, nil)
	mustache.template_destroy(&tmpl)
	mustache.template_destroy(&tmpl)
	testing.expect_value(t, len(tmpl.nodes), 0)
}

// ---- Malformed templates ----

@(test)
test_compile_rejects_unclosed_tags :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "Hello {{name", .Unclosed_Tag)
	expect_compile_error(t, "Hello {{", .Unclosed_Tag)
	expect_compile_error(t, "{{{name}}", .Unclosed_Tag)
	expect_compile_error(t, "{{! never closed", .Unclosed_Tag)
	expect_compile_error(t, "{{=<% %>", .Unclosed_Tag)
}

@(test)
test_compile_rejects_empty_tags :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{}}", .Empty_Tag)
	expect_compile_error(t, "{{   }}", .Empty_Tag)
	expect_compile_error(t, "{{{}}}", .Empty_Tag)
	expect_compile_error(t, "{{#}}{{/}}", .Empty_Tag)
	expect_compile_error(t, "{{>}}", .Empty_Tag)
	expect_compile_error(t, "{{>*}}", .Empty_Tag)
}

@(test)
test_compile_rejects_invalid_names :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{first name}}", .Invalid_Name)
	expect_compile_error(t, "{{a..b}}", .Invalid_Name)
	expect_compile_error(t, "{{.a}}", .Invalid_Name)
	expect_compile_error(t, "{{a.}}", .Invalid_Name)
	expect_compile_error(t, "{{#a b}}{{/a b}}", .Invalid_Name)
	expect_compile_error(t, "{{>*.}}", .Invalid_Name)
}

@(test)
test_compile_rejects_unclosed_section :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{#a}}never closed", .Unclosed_Section)
	expect_compile_error(t, "{{#a}}{{#b}}{{c}}{{/b}}", .Unclosed_Section)
	expect_compile_error(t, "{{^a}}", .Unclosed_Section)
}

@(test)
test_compile_rejects_unexpected_close :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "text{{/a}}", .Unexpected_Close)
	expect_compile_error(t, "{{#a}}{{/a}}{{/a}}", .Unexpected_Close)
}

@(test)
test_compile_rejects_mismatched_close :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{#a}}{{#b}}{{/a}}{{/b}}", .Mismatched_Close)
	expect_compile_error(t, "{{#a.b}}{{/a}}", .Mismatched_Close)
}

@(test)
test_compile_rejects_bad_delimiters :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{=<%=}}", .Invalid_Delimiters)
	expect_compile_error(t, "{{= =}}", .Invalid_Delimiters)
	expect_compile_error(t, "{{=<% %> x=}}", .Invalid_Delimiters)
	expect_compile_error(t, "{{=a= b=}}", .Invalid_Delimiters)
	// The tag is closed but lacks the "=" before the closing delimiter.
	expect_compile_error(t, "{{=}}", .Invalid_Delimiters)
	expect_compile_error(t, "{{=<% %>}} text", .Invalid_Delimiters)
	expect_compile_error(t, "{{=<% %>", .Unclosed_Tag)
}

// nested_sections returns `depth` nested `{{#a}}` sections around "x".
nested_sections :: proc(depth: int) -> string {
	b := strings.builder_make()
	for _ in 0 ..< depth {
		strings.write_string(&b, "{{#a}}")
	}
	strings.write_byte(&b, 'x')
	for _ in 0 ..< depth {
		strings.write_string(&b, "{{/a}}")
	}
	return strings.to_string(b)
}

@(test)
test_compile_limits_section_nesting :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	deepest := nested_sections(mustache.MAX_NESTING_DEPTH)
	defer delete(deepest)
	expect_render(t, deepest, mustache.Object{{"a", true}}, "x")

	too_deep := nested_sections(mustache.MAX_NESTING_DEPTH + 1)
	defer delete(too_deep)
	expect_compile_error(t, too_deep, .Too_Deeply_Nested)
	_, loc, _ := mustache.compile_with_location(too_deep)
	testing.expect_value(t, loc.offset, mustache.MAX_NESTING_DEPTH * len("{{#a}}"))

	// Before the limit, rendering this many levels overflowed the stack.
	hostile := nested_sections(100_000)
	defer delete(hostile)
	expect_compile_error(t, hostile, .Too_Deeply_Nested)
}

@(test)
test_compile_rejects_inheritance_tags :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_compile_error(t, "{{<parent}}{{/parent}}", .Unsupported_Tag)
	expect_compile_error(t, "{{$block}}default{{/block}}", .Unsupported_Tag)
}

@(test)
test_compile_errors_free_partial_trees :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	// Several open sections with children, then a failure deep inside: the
	// leak tracker fails this test if any node, name or frame survives.
	expect_compile_error(t, "{{#a}}x{{b.c}}{{#d}}{{>p}}{{^e}}{{f}}{{{g.h}}}{{x y}}", .Invalid_Name)
	expect_compile_error(t, "{{#a}}{{#b}}{{c}}text{{/a}}", .Mismatched_Close)
}

@(test)
test_compile_with_location_points_at_the_tag :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, loc, err := mustache.compile_with_location("line one\nline {{two}} and {{bad name}}\n")
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, mustache.Error(mustache.Parse_Error.Invalid_Name))
	testing.expect_value(t, loc, mustache.Location{offset = 26, line = 2, column = 18})
}

@(test)
test_compile_with_location_unclosed_section_points_at_opening :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	_, loc, err := mustache.compile_with_location("a\n\n  {{#items}}\n{{.}}\n")
	testing.expect_value(t, err, mustache.Error(mustache.Parse_Error.Unclosed_Section))
	testing.expect_value(t, loc.line, 3)
	testing.expect_value(t, loc.column, 3)
}

@(test)
test_compile_with_location_is_zero_on_success :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, loc, err := mustache.compile_with_location("{{a}}")
	defer mustache.template_destroy(&tmpl)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, loc, mustache.Location{})
}

@(test)
test_set_delimiters_reach_into_sections :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"list", mustache.List{"a", "b"}}}
	expect_render(t, "{{=<% %>=}}<%#list%>[<%.%>]<%/list%>{{list}}", data, "[a][b]{{list}}")
	expect_render(t, "{{=| |=}}|{x}|", mustache.Object{{"x", "<"}}, "<")
}

// ---- Rendering Value data ----

@(test)
test_render_object_literal :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"name", "Chris"}, {"value", i64(10000)}, {"in_ca", true}}
	expect_render(t, "Hello {{name}}. You won {{value}} dollars{{#in_ca}}, taxes apply{{/in_ca}}.", data, "Hello Chris. You won 10000 dollars, taxes apply.")
}

@(test)
test_render_map_value :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	m := make(mustache.Map)
	defer delete(m)
	m["planet"] = "Mars"
	m["moons"] = i64(2)
	expect_render(t, "{{planet}} has {{moons}} moons", m, "Mars has 2 moons")
}

@(test)
test_render_list_of_objects :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"repo", mustache.List{mustache.Object{{"name", "odin"}}, mustache.Object{{"name", "mustache"}}}}}
	expect_render(t, "{{#repo}}<b>{{name}}</b>{{/repo}}", data, "<b>odin</b><b>mustache</b>")
}

@(test)
test_render_dotted_names_through_objects_and_maps :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	inner := make(mustache.Map)
	defer delete(inner)
	inner["c"] = "deep"
	data := mustache.Object{{"a", mustache.Object{{"b", inner}}}}
	expect_render(t, "{{a.b.c}}|{{a.b.missing}}|{{a.x.c}}", data, "deep||")
}

@(test)
test_render_dotted_name_does_not_fall_back_to_outer_context :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"a", mustache.Object{{"b", mustache.Object{}}}}, {"b", mustache.Object{{"c", "ERROR"}}}}
	expect_render(t, "{{#a}}[{{b.c}}]{{/a}}", data, "[]")
}

@(test)
test_render_null_field_masks_outer_context :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"inner", mustache.Object{{"name", nil}}}, {"name", "outer"}}
	expect_render(t, "{{#inner}}[{{name}}]{{/inner}}", data, "[]")
}

@(test)
test_render_object_first_field_wins :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_render(t, "{{k}}", mustache.Object{{"k", "first"}, {"k", "second"}}, "first")
}

@(test)
test_render_integers :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"zero", i64(0)}, {"neg", i64(-42)}, {"max", i64(max(i64))}, {"min", i64(min(i64))}}
	expect_render(t, "{{zero}} {{neg}} {{max}} {{min}}", data, "0 -42 9223372036854775807 -9223372036854775808")
}

@(test)
test_render_floats_like_javascript :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object {
		{"a", 1.21},
		{"b", 100.0},
		{"c", -0.5},
		{"d", 1e21},
		{"e", 1e-7},
		{"f", 0.000001},
		{"g", 123456789012.0},
		{"h", -0.0},
		{"i", 2.5e-12},
	}
	expect_render(t, "{{a}} {{b}} {{c}} {{d}} {{e}} {{f}} {{g}} {{h}} {{i}}", data, "1.21 100 -0.5 1e+21 1e-7 0.000001 123456789012 0 2.5e-12")
}

@(test)
test_render_float_special_values :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"nan", math.nan_f64()}, {"inf", math.inf_f64(1)}, {"ninf", math.inf_f64(-1)}}
	expect_render(t, "{{nan}} {{inf}} {{ninf}}", data, "NaN Infinity -Infinity")
}

@(test)
test_render_booleans_interpolate_as_words :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_render(t, "{{yes}}/{{no}}", mustache.Object{{"yes", true}, {"no", false}}, "true/false")
}

@(test)
test_render_escapes_html :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"s", `<a href="x?a=1&b=2">it's</a>`}}
	expect_render(t, "{{s}}", data, `&lt;a href=&quot;x?a=1&amp;b=2&quot;&gt;it's&lt;/a&gt;`)
	expect_render(t, "{{s}}", mustache.Object{{"s", "plain"}}, "plain")
	expect_render(t, "{{s}}", mustache.Object{{"s", "&&"}}, "&amp;&amp;")
}

@(test)
test_render_unescaped_forms :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"s", "<b>&</b>"}}
	expect_render(t, "{{{s}}}|{{& s }}|{{{ s }}}", data, "<b>&</b>|<b>&</b>|<b>&</b>")
}

@(test)
test_render_containers_interpolate_as_empty :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"l", mustache.List{"x"}}, {"o", mustache.Object{{"k", "v"}}}, {"n", nil}}
	expect_render(t, "[{{l}}][{{o}}][{{n}}][{{missing}}]", data, "[][][][]")
}

@(test)
test_render_truthiness :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object {
		{"empty_string", ""},
		{"zero", i64(0)},
		{"zero_float", 0.0},
		{"empty_object", mustache.Object{}},
		{"empty_list", mustache.List{}},
		{"null", nil},
		{"no", false},
	}
	// Only false, null, missing names and empty lists are falsey.
	source := "{{#empty_string}}s{{/empty_string}}{{#zero}}z{{/zero}}{{#zero_float}}f{{/zero_float}}" +
		"{{#empty_object}}o{{/empty_object}}{{#empty_list}}L{{/empty_list}}{{#null}}N{{/null}}" +
		"{{#no}}F{{/no}}{{#missing}}M{{/missing}}"
	expect_render(t, source, data, "szfo")
}

@(test)
test_render_inverted_sections :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"items", mustache.List{}}, {"user", mustache.Object{{"name", "Ann"}}}}
	expect_render(t, "{{^items}}No items.{{/items}}{{^user}}Anonymous{{/user}}", data, "No items.")
}

@(test)
test_render_section_pushes_scalar_context :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_render(t, "{{#n}}<{{.}}>{{/n}}", mustache.Object{{"n", i64(7)}}, "<7>")
}

@(test)
test_render_nested_lists_with_implicit_iterator :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data := mustache.Object{{"rows", mustache.List{mustache.List{i64(1), i64(2)}, mustache.List{i64(3)}}}}
	expect_render(t, "{{#rows}}({{#.}}{{.}}{{/.}}){{/rows}}", data, "(12)(3)")
}

@(test)
test_render_nil_root_context :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_render(t, "[{{a}}]{{#a}}x{{/a}}{{^a}}y{{/a}}[{{.}}]", nil, "[]y[]")
}

@(test)
test_render_scalar_root_context :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	expect_render(t, "{{.}} {{name}}", "root", "root ")
}

@(test)
test_render_reuses_one_template :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("{{#user}}{{name}}{{/user}}{{^user}}nobody{{/user}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	names := [?]string{"Ann", "Bob", "Cy"}
	for name in names {
		out, rerr := mustache.render(tmpl, mustache.Object{{"user", mustache.Object{{"name", name}}}})
		testing.expect_value(t, rerr, nil)
		testing.expect_value(t, out, name)
		delete(out)
	}
	out, rerr := mustache.render(tmpl, mustache.Object{})
	defer delete(out)
	testing.expect_value(t, rerr, nil)
	testing.expect_value(t, out, "nobody")
}

@(test)
test_render_string_one_shot :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	out, err := mustache.render_string("{{a}}+{{b}}", mustache.Object{{"a", i64(1)}, {"b", i64(2)}})
	defer delete(out)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, out, "1+2")
}

@(test)
test_render_string_reports_parse_errors :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	out, err := mustache.render_string("{{#a}}", nil)
	testing.expect_value(t, err, mustache.Error(mustache.Parse_Error.Unclosed_Section))
	testing.expect_value(t, out, "")
}

@(test)
test_render_uses_the_given_allocator :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("{{#l}}{{.}},{{/l}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	buf: [4096]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	out, rerr := mustache.render(tmpl, mustache.Object{{"l", mustache.List{"a", "b"}}}, nil, mem.arena_allocator(&arena))
	testing.expect_value(t, rerr, nil)
	testing.expect_value(t, out, "a,b,")
	testing.expect(t, arena.offset > 0)
	// Nothing came from context.allocator, so the leak tracker stays empty without a delete.
}

// ---- Writers ----

@(test)
test_render_to_writer_streams_into_a_builder :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("<{{x}}>")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	strings.write_string(&b, "start:")
	werr := mustache.render_to_writer(strings.to_writer(&b), tmpl, mustache.Object{{"x", "&"}})
	testing.expect_value(t, werr, nil)
	testing.expect_value(t, strings.to_string(b), "start:<&amp;>")
}

failing_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	#partial switch mode {
	case .Write:
		return 0, .Short_Write
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(test)
test_render_to_writer_returns_writer_errors :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	tmpl, err := mustache.compile("text {{x}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	w := io.Stream{procedure = failing_writer_proc}
	werr := mustache.render_to_writer(w, tmpl, nil)
	testing.expect_value(t, werr, mustache.Error(io.Error.Short_Write))
}

// ---- JSON data ----

@(test)
test_render_json_reads_values_in_place :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data, jerr := json.parse_string(`{"title": "Posts", "posts": [{"id": 1, "tags": ["a", "b"]}, {"id": 2, "tags": []}], "draft": null}`, parse_integers = true)
	defer json.destroy_value(data)
	testing.expect_value(t, jerr, nil)

	tmpl, err := mustache.compile("{{title}}:{{#posts}} #{{id}}{{#tags}}[{{.}}]{{/tags}}{{^tags}}(none){{/tags}}{{/posts}}{{#draft}}!{{/draft}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	out, rerr := mustache.render_json(tmpl, data)
	defer delete(out)
	testing.expect_value(t, rerr, nil)
	testing.expect_value(t, out, "Posts: #1[a][b] #2(none)")
}

@(test)
test_render_json_to_writer :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	data, jerr := json.parse_string(`{"n": 2.50, "ok": true}`)
	defer json.destroy_value(data)
	testing.expect_value(t, jerr, nil)

	tmpl, err := mustache.compile("{{n}} {{ok}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	testing.expect_value(t, mustache.render_json_to_writer(strings.to_writer(&b), tmpl, data), nil)
	testing.expect_value(t, strings.to_string(b), "2.5 true")
}

@(test)
test_from_json_makes_an_independent_copy :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	raw, jerr := json.parse_string(`{"user": {"name": "Ann", "langs": ["odin", "go"]}, "n": 3, "f": 0.5, "b": false, "z": null}`, parse_integers = true)
	testing.expect_value(t, jerr, nil)
	v, err := mustache.from_json(raw)
	json.destroy_value(raw) // The copy must survive this.
	defer mustache.value_destroy(v)
	testing.expect_value(t, err, nil)

	m, ok := v.(mustache.Map)
	if !testing.expect(t, ok) {
		return
	}
	testing.expect_value(t, m["n"].(i64) or_else 0, 3)
	testing.expect_value(t, m["f"].(f64) or_else 0, 0.5)
	testing.expect_value(t, m["b"].(bool) or_else true, false)
	testing.expect(t, "z" in m && m["z"] == nil)
	expect_render(t, "{{user.name}}:{{#user.langs}} {{.}}{{/user.langs}}", v, "Ann: odin go")
}

@(test)
test_value_destroy_frees_heap_objects :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	fields := make(mustache.Object, 2)
	fields[0] = {strings.clone("name"), strings.clone("Ann")}
	list := make(mustache.List, 1)
	list[0] = strings.clone("x")
	fields[1] = {strings.clone("tags"), list}
	expect_render(t, "{{name}}{{#tags}}-{{.}}{{/tags}}", fields, "Ann-x")
	mustache.value_destroy(fields)
}

// ---- Partials ----

@(test)
test_partials_missing_name_renders_empty :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	expect_render(t, "[{{>nope}}]", nil, "[]", &partials)
	expect_render(t, "[{{>nope}}]", nil, "[]", nil)
}

@(test)
test_partials_add_replaces_existing :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "p", "old"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "p", "new {{x}}"), nil)
	testing.expect_value(t, len(partials.templates), 1)
	expect_render(t, "{{>p}}", mustache.Object{{"x", "!"}}, "new !", &partials)
}

@(test)
test_partials_add_rejects_bad_source :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "ok", "fine"), nil)
	err := mustache.partials_add(&partials, "ok", "{{#broken}}")
	testing.expect_value(t, err, mustache.Error(mustache.Parse_Error.Unclosed_Section))
	expect_render(t, "{{>ok}}", nil, "fine", &partials)
}

@(test)
test_partials_add_template_takes_ownership :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)

	name := strings.clone("row")
	tmpl, err := mustache.compile("<li>{{.}}</li>")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, mustache.partials_add_template(&partials, name, tmpl), nil)
	delete(name) // The registry keeps its own copy of the name.
	expect_render(t, "{{#l}}{{>row}}{{/l}}", mustache.Object{{"l", mustache.List{"a", "b"}}}, "<li>a</li><li>b</li>", &partials)
}

@(test)
test_partials_zero_value_is_ready_to_use :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	// No partials_init: the zero value must adopt context.allocator, as Odin maps do.
	partials: mustache.Partials
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "greet", "hello {{x}}"), nil)
	tmpl, err := mustache.compile("[{{x}}]")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, mustache.partials_add_template(&partials, "wrap", tmpl), nil)
	expect_render(t, "{{>greet}} {{>wrap}}", mustache.Object{{"x", "y"}}, "hello y [y]", &partials)
}

@(test)
test_partials_runaway_recursion_is_an_error :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "loop", "x{{>loop}}"), nil)

	tmpl, err := mustache.compile("{{>loop}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)
	out, rerr := mustache.render(tmpl, nil, &partials)
	testing.expect_value(t, rerr, mustache.Error(mustache.Render_Error.Partial_Depth_Exceeded))
	testing.expect_value(t, out, "")
}

@(test)
test_partials_nesting_with_sections_is_bounded :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	// Each level nests three sections and a partial, so the total nesting
	// reaches MAX_NESTING_DEPTH long before the partial depth limit.
	testing.expect_value(t, mustache.partials_add(&partials, "p", "{{#a}}{{#a}}{{#a}}{{>p}}{{/a}}{{/a}}{{/a}}"), nil)

	tmpl, err := mustache.compile("{{>p}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)
	out, rerr := mustache.render(tmpl, mustache.Object{{"a", true}}, &partials)
	testing.expect_value(t, rerr, mustache.Error(mustache.Render_Error.Nesting_Depth_Exceeded))
	testing.expect_value(t, out, "")
}

@(test)
test_partials_recursion_within_the_limit_works :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "node", "{{name}}({{#kids}}{{>node}}{{/kids}})"), nil)
	// A leaf needs its own empty list: a missing "kids" would resolve to the parent's list.
	leaf := mustache.Object{{"name", "c"}, {"kids", mustache.List{}}}
	mid := mustache.Object{{"name", "b"}, {"kids", mustache.List{leaf}}}
	root := mustache.Object{{"name", "a"}, {"kids", mustache.List{mid, leaf}}}
	expect_render(t, "{{>node}}", root, "a(b(c())c())", &partials)
}

@(test)
test_partials_nested_standalone_indentation_accumulates :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "outer", "<ul>\n  {{>inner}}\n</ul>\n"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "inner", "{{#items}}\n<li>{{.}}</li>\n{{/items}}\n"), nil)
	data := mustache.Object{{"items", mustache.List{"a", "b"}}}
	expect_render(t, "<div>\n  {{>outer}}\n</div>\n", data, "<div>\n  <ul>\n    <li>a</li>\n    <li>b</li>\n  </ul>\n</div>\n", &partials)
}

@(test)
test_partials_indentation_skips_interpolated_newlines :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "p", "[{{{v}}}]\n[{{v}}]\n"), nil)
	expect_render(t, "  {{>p}}\n", mustache.Object{{"v", "1\n2"}}, "  [1\n2]\n  [1\n2]\n", &partials)
}

@(test)
test_partials_indentation_after_partial_without_trailing_newline :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	// The spec indents every line of a partial before rendering it. A partial
	// that doesn't end in a newline leaves the next text on the same line, so
	// that text must not get a second copy of the indentation.
	testing.expect_value(t, mustache.partials_add(&partials, "x", "x"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "yz", "y\nz\n"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "text_after", "{{>x}}\ny\n"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "partial_after", "{{>x}}\n{{>yz}}\n"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "indented_after", "{{>x}}\n  {{>yz}}\n"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "section_after", "{{#t}}\n{{>x}}\n{{/t}}\nq\n"), nil)
	data := mustache.Object{{"t", true}}
	expect_render(t, "  {{>text_after}}\n", data, "  xy\n", &partials)
	expect_render(t, "  {{>partial_after}}\n", data, "  xy\n  z\n", &partials)
	expect_render(t, "  {{>indented_after}}\n", data, "  x  y\n    z\n", &partials)
	expect_render(t, "  {{>section_after}}\n", data, "  xq\n", &partials)
	// At the top level nothing changes: there is no outer indentation to repeat.
	expect_render(t, "{{>x}}\n{{>yz}}\n", data, "xy\nz\n", &partials)
}

@(test)
test_partials_dynamic_name_must_be_a_string :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "1", "one"), nil)
	testing.expect_value(t, mustache.partials_add(&partials, "card", "<{{title}}>"), nil)
	data := mustache.Object{{"kind", i64(1)}, {"view", "card"}, {"title", "T"}}
	expect_render(t, "[{{>*kind}}][{{>*view}}][{{>*nope}}]", data, "[][<T>][]", &partials)
}

@(test)
test_partials_keep_their_own_delimiters :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "p", "{{x}}{{=[ ]=}}[x]"), nil)
	expect_render(t, "{{=<% %>=}}<%>p%><%x%>{{x}}", mustache.Object{{"x", "1"}}, "111{{x}}", &partials)
}

// ---- Allocation failures ----

// Each test below fails the first, second, third... allocation in turn until
// the call succeeds. The leak tracker underneath proves every error path frees
// what it allocated.

@(test)
test_compile_survives_every_allocation_failure :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	source := "a{{#s}}{{x.y.z}}{{^n}}{{>p}}{{>*d.e}}{{/n}}{{{raw}}}\n  {{#t}}\n{{/t}}\n{{/s}}b"
	succeeded := false
	for n in 0 ..< 500 {
		fa := Failing_Allocator{backing = context.allocator, remaining = n}
		tmpl, err := mustache.compile(source, failing_allocator(&fa))
		if err == nil {
			mustache.template_destroy(&tmpl)
			succeeded = true
			testing.expect(t, n > 3, "compile should need several allocations")
			break
		}
		testing.expect_value(t, err, mustache.Error(runtime.Allocator_Error.Out_Of_Memory))
		testing.expect_value(t, len(tmpl.nodes), 0)
	}
	testing.expect(t, succeeded)
}

@(test)
test_render_survives_every_allocation_failure :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "p", "  <{{.}}>\n"), nil)
	tmpl, err := mustache.compile("{{#l}}\n  {{>p}}\n{{/l}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	big := strings.repeat("x", 300)
	defer delete(big)
	data := mustache.Object{{"l", mustache.List{"a", big, "c"}}}
	succeeded := false
	for n in 0 ..< 500 {
		fa := Failing_Allocator{backing = context.allocator, remaining = n}
		out, rerr := mustache.render(tmpl, data, &partials, failing_allocator(&fa))
		if rerr == nil {
			testing.expect(t, strings.has_prefix(out, "    <a>\n    <xxx"))
			delete(out)
			succeeded = true
			break
		}
		testing.expect_value(t, out, "")
	}
	testing.expect(t, succeeded)
}

@(test)
test_from_json_survives_every_allocation_failure :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	raw, jerr := json.parse_string(`{"a": [1, "two", {"b": "c", "d": [true, null]}], "e": "f", "g": {}}`)
	defer json.destroy_value(raw)
	testing.expect_value(t, jerr, nil)
	succeeded := false
	for n in 0 ..< 500 {
		fa := Failing_Allocator{backing = context.allocator, remaining = n}
		v, err := mustache.from_json(raw, failing_allocator(&fa))
		if err == nil {
			mustache.value_destroy(v, failing_allocator(&fa))
			succeeded = true
			break
		}
		testing.expect_value(t, err, mustache.Error(runtime.Allocator_Error.Out_Of_Memory))
		testing.expect(t, v == nil)
	}
	testing.expect(t, succeeded)
}

@(test)
test_partials_add_survives_every_allocation_failure :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	succeeded := false
	for n in 0 ..< 200 {
		fa := Failing_Allocator{backing = context.allocator, remaining = n}
		partials: mustache.Partials
		mustache.partials_init(&partials, failing_allocator(&fa))
		err := mustache.partials_add(&partials, "row", "<li>{{#a}}{{b.c}}{{/a}}</li>")
		if err == nil {
			testing.expect_value(t, len(partials.templates), 1)
			succeeded = true
		} else {
			testing.expect_value(t, len(partials.templates), 0)
		}
		fa.remaining = max(int)
		mustache.partials_destroy(&partials)
		if succeeded {
			break
		}
	}
	testing.expect(t, succeeded)
}

// ---- Concurrency ----

Thread_Job :: struct {
	tmpl:     ^mustache.Template,
	partials: ^mustache.Partials,
	failures: ^int,
}

@(test)
test_render_shared_template_from_several_threads :: proc(t: ^testing.T) {
	context.allocator = track_leaks(t).allocator
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	testing.expect_value(t, mustache.partials_add(&partials, "item", "<{{.}}>"), nil)
	tmpl, err := mustache.compile("{{#l}}{{>item}}{{/l}}")
	testing.expect_value(t, err, nil)
	defer mustache.template_destroy(&tmpl)

	failures := 0
	job := Thread_Job{&tmpl, &partials, &failures}
	threads: [4]^thread.Thread
	for &th in threads {
		// The tracking allocator isn't thread safe, so each thread uses the heap.
		th = thread.create_and_start_with_poly_data(job, proc(job: Thread_Job) {
			context.allocator = runtime.heap_allocator()
			for _ in 0 ..< 200 {
				out, rerr := mustache.render(job.tmpl^, mustache.Object{{"l", mustache.List{"a", "b", "c"}}}, job.partials)
				if rerr != nil || out != "<a><b><c>" {
					sync.atomic_add(job.failures, 1)
				}
				delete(out)
			}
		}, init_context = runtime.default_context())
	}
	for th in threads {
		thread.join(th)
		thread.destroy(th)
	}
	testing.expect_value(t, failures, 0)
}
