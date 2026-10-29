// Code generated from the Mustache specification v1.4.3; DO NOT EDIT.
// Source: https://github.com/mustache/spec/tree/v1.4.3/specs
// Regenerate with the script described in CONTRIBUTING.md.
package mustache_tests

import "core:testing"

@(test)
test_spec_comments_inline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Inline",
		template = "12345{{! Comment Block! }}67890",
		data     = "{}",
		expected = "1234567890",
	})
}

@(test)
test_spec_comments_multiline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Multiline",
		template = "12345{{!\n  This is a\n  multi-line comment...\n}}67890\n",
		data     = "{}",
		expected = "1234567890\n",
	})
}

@(test)
test_spec_comments_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Standalone",
		template = "Begin.\n{{! Comment Block! }}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_comments_indented_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Indented Standalone",
		template = "Begin.\n  {{! Indented Comment Block! }}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_comments_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Standalone Line Endings",
		template = "|\r\n{{! Standalone Comment }}\r\n|",
		data     = "{}",
		expected = "|\r\n|",
	})
}

@(test)
test_spec_comments_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Standalone Without Previous Line",
		template = "  {{! I'm Still Standalone }}\n!",
		data     = "{}",
		expected = "!",
	})
}

@(test)
test_spec_comments_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Standalone Without Newline",
		template = "!\n  {{! I'm Still Standalone }}",
		data     = "{}",
		expected = "!\n",
	})
}

@(test)
test_spec_comments_multiline_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Multiline Standalone",
		template = "Begin.\n{{!\nSomething's going on here...\n}}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_comments_indented_multiline_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Indented Multiline Standalone",
		template = "Begin.\n  {{!\n    Something's going on here...\n  }}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_comments_indented_inline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Indented Inline",
		template = "  12 {{! 34 }}\n",
		data     = "{}",
		expected = "  12 \n",
	})
}

@(test)
test_spec_comments_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Surrounding Whitespace",
		template = "12345 {{! Comment Block! }} 67890",
		data     = "{}",
		expected = "12345  67890",
	})
}

@(test)
test_spec_comments_variable_name_collision :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "comments: Variable Name Collision",
		template = "comments never show: >{{! comment }}<",
		data     = "{\"! comment\": 1, \"! comment \": 2, \"!comment\": 3, \"comment\": 4}",
		expected = "comments never show: ><",
	})
}

@(test)
test_spec_delimiters_pair_behavior :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Pair Behavior",
		template = "{{=<% %>=}}(<%text%>)",
		data     = "{\"text\": \"Hey!\"}",
		expected = "(Hey!)",
	})
}

@(test)
test_spec_delimiters_special_characters :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Special Characters",
		template = "({{=[ ]=}}[text])",
		data     = "{\"text\": \"It worked!\"}",
		expected = "(It worked!)",
	})
}

@(test)
test_spec_delimiters_sections :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Sections",
		template = "[\n{{#section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|#section|\n  {{data}}\n  |data|\n|/section|\n]\n",
		data     = "{\"data\": \"I got interpolated.\", \"section\": true}",
		expected = "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n",
	})
}

@(test)
test_spec_delimiters_inverted_sections :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Inverted Sections",
		template = "[\n{{^section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|^section|\n  {{data}}\n  |data|\n|/section|\n]\n",
		data     = "{\"data\": \"I got interpolated.\", \"section\": false}",
		expected = "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n",
	})
}

@(test)
test_spec_delimiters_partial_inheritence :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Partial Inheritence",
		template = "[ {{>include}} ]\n{{= | | =}}\n[ |>include| ]\n",
		data     = "{\"value\": \"yes\"}",
		partials = {
			{"include", ".{{value}}."},
		},
		expected = "[ .yes. ]\n[ .yes. ]\n",
	})
}

@(test)
test_spec_delimiters_post_partial_behavior :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Post-Partial Behavior",
		template = "[ {{>include}} ]\n[ .{{value}}.  .|value|. ]\n",
		data     = "{\"value\": \"yes\"}",
		partials = {
			{"include", ".{{value}}. {{= | | =}} .|value|."},
		},
		expected = "[ .yes.  .yes. ]\n[ .yes.  .|value|. ]\n",
	})
}

@(test)
test_spec_delimiters_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Surrounding Whitespace",
		template = "| {{=@ @=}} |",
		data     = "{}",
		expected = "|  |",
	})
}

@(test)
test_spec_delimiters_outlying_whitespace_inline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Outlying Whitespace (Inline)",
		template = " | {{=@ @=}}\n",
		data     = "{}",
		expected = " | \n",
	})
}

@(test)
test_spec_delimiters_standalone_tag :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Standalone Tag",
		template = "Begin.\n{{=@ @=}}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_delimiters_indented_standalone_tag :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Indented Standalone Tag",
		template = "Begin.\n  {{=@ @=}}\nEnd.\n",
		data     = "{}",
		expected = "Begin.\nEnd.\n",
	})
}

@(test)
test_spec_delimiters_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Standalone Line Endings",
		template = "|\r\n{{= @ @ =}}\r\n|",
		data     = "{}",
		expected = "|\r\n|",
	})
}

@(test)
test_spec_delimiters_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Standalone Without Previous Line",
		template = "  {{=@ @=}}\n=",
		data     = "{}",
		expected = "=",
	})
}

@(test)
test_spec_delimiters_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Standalone Without Newline",
		template = "=\n  {{=@ @=}}",
		data     = "{}",
		expected = "=\n",
	})
}

@(test)
test_spec_delimiters_pair_with_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "delimiters: Pair with Padding",
		template = "|{{= @   @ =}}|",
		data     = "{}",
		expected = "||",
	})
}

@(test)
test_spec_interpolation_no_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: No Interpolation",
		template = "Hello from {Mustache}!\n",
		data     = "{}",
		expected = "Hello from {Mustache}!\n",
	})
}

@(test)
test_spec_interpolation_basic_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Basic Interpolation",
		template = "Hello, {{subject}}!\n",
		data     = "{\"subject\": \"world\"}",
		expected = "Hello, world!\n",
	})
}

@(test)
test_spec_interpolation_no_re_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: No Re-interpolation",
		template = "{{template}}: {{planet}}",
		data     = "{\"planet\": \"Earth\", \"template\": \"{{planet}}\"}",
		expected = "{{planet}}: Earth",
	})
}

@(test)
test_spec_interpolation_html_escaping :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: HTML Escaping",
		template = "These characters should be HTML escaped: {{forbidden}}\n",
		data     = "{\"forbidden\": \"& \\\" < >\"}",
		expected = "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
	})
}

@(test)
test_spec_interpolation_triple_mustache :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache",
		template = "These characters should not be HTML escaped: {{{forbidden}}}\n",
		data     = "{\"forbidden\": \"& \\\" < >\"}",
		expected = "These characters should not be HTML escaped: & \" < >\n",
	})
}

@(test)
test_spec_interpolation_ampersand :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand",
		template = "These characters should not be HTML escaped: {{&forbidden}}\n",
		data     = "{\"forbidden\": \"& \\\" < >\"}",
		expected = "These characters should not be HTML escaped: & \" < >\n",
	})
}

@(test)
test_spec_interpolation_basic_integer_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Basic Integer Interpolation",
		template = "\"{{mph}} miles an hour!\"",
		data     = "{\"mph\": 85}",
		expected = "\"85 miles an hour!\"",
	})
}

@(test)
test_spec_interpolation_triple_mustache_integer_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache Integer Interpolation",
		template = "\"{{{mph}}} miles an hour!\"",
		data     = "{\"mph\": 85}",
		expected = "\"85 miles an hour!\"",
	})
}

@(test)
test_spec_interpolation_ampersand_integer_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand Integer Interpolation",
		template = "\"{{&mph}} miles an hour!\"",
		data     = "{\"mph\": 85}",
		expected = "\"85 miles an hour!\"",
	})
}

@(test)
test_spec_interpolation_basic_decimal_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Basic Decimal Interpolation",
		template = "\"{{power}} jiggawatts!\"",
		data     = "{\"power\": 1.21}",
		expected = "\"1.21 jiggawatts!\"",
	})
}

@(test)
test_spec_interpolation_triple_mustache_decimal_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache Decimal Interpolation",
		template = "\"{{{power}}} jiggawatts!\"",
		data     = "{\"power\": 1.21}",
		expected = "\"1.21 jiggawatts!\"",
	})
}

@(test)
test_spec_interpolation_ampersand_decimal_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand Decimal Interpolation",
		template = "\"{{&power}} jiggawatts!\"",
		data     = "{\"power\": 1.21}",
		expected = "\"1.21 jiggawatts!\"",
	})
}

@(test)
test_spec_interpolation_basic_null_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Basic Null Interpolation",
		template = "I ({{cannot}}) be seen!",
		data     = "{\"cannot\": null}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_triple_mustache_null_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache Null Interpolation",
		template = "I ({{{cannot}}}) be seen!",
		data     = "{\"cannot\": null}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_ampersand_null_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand Null Interpolation",
		template = "I ({{&cannot}}) be seen!",
		data     = "{\"cannot\": null}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_basic_context_miss_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Basic Context Miss Interpolation",
		template = "I ({{cannot}}) be seen!",
		data     = "{}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_triple_mustache_context_miss_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache Context Miss Interpolation",
		template = "I ({{{cannot}}}) be seen!",
		data     = "{}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_ampersand_context_miss_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand Context Miss Interpolation",
		template = "I ({{&cannot}}) be seen!",
		data     = "{}",
		expected = "I () be seen!",
	})
}

@(test)
test_spec_interpolation_dotted_names_basic_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Basic Interpolation",
		template = "\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\"",
		data     = "{\"person\": {\"name\": \"Joe\"}}",
		expected = "\"Joe\" == \"Joe\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_triple_mustache_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Triple Mustache Interpolation",
		template = "\"{{{person.name}}}\" == \"{{#person}}{{{name}}}{{/person}}\"",
		data     = "{\"person\": {\"name\": \"Joe\"}}",
		expected = "\"Joe\" == \"Joe\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_ampersand_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Ampersand Interpolation",
		template = "\"{{&person.name}}\" == \"{{#person}}{{&name}}{{/person}}\"",
		data     = "{\"person\": {\"name\": \"Joe\"}}",
		expected = "\"Joe\" == \"Joe\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_arbitrary_depth :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Arbitrary Depth",
		template = "\"{{a.b.c.d.e.name}}\" == \"Phil\"",
		data     = "{\"a\": {\"b\": {\"c\": {\"d\": {\"e\": {\"name\": \"Phil\"}}}}}}",
		expected = "\"Phil\" == \"Phil\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_broken_chains :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Broken Chains",
		template = "\"{{a.b.c}}\" == \"\"",
		data     = "{\"a\": {}}",
		expected = "\"\" == \"\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_broken_chain_resolution :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Broken Chain Resolution",
		template = "\"{{a.b.c.name}}\" == \"\"",
		data     = "{\"a\": {\"b\": {}}, \"c\": {\"name\": \"Jim\"}}",
		expected = "\"\" == \"\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_initial_resolution :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Initial Resolution",
		template = "\"{{#a}}{{b.c.d.e.name}}{{/a}}\" == \"Phil\"",
		data     = "{\"a\": {\"b\": {\"c\": {\"d\": {\"e\": {\"name\": \"Phil\"}}}}}, \"b\": {\"c\": {\"d\": {\"e\": {\"name\": \"Wrong\"}}}}}",
		expected = "\"Phil\" == \"Phil\"",
	})
}

@(test)
test_spec_interpolation_dotted_names_context_precedence :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - Context Precedence",
		template = "{{#a}}{{b.c}}{{/a}}",
		data     = "{\"a\": {\"b\": {}}, \"b\": {\"c\": \"ERROR\"}}",
		expected = "",
	})
}

@(test)
test_spec_interpolation_dotted_names_are_never_single_keys :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names are never single keys",
		template = "{{a.b}}",
		data     = "{\"a.b\": \"c\"}",
		expected = "",
	})
}

@(test)
test_spec_interpolation_dotted_names_no_masking :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Dotted Names - No Masking",
		template = "{{a.b}}",
		data     = "{\"a\": {\"b\": \"d\"}, \"a.b\": \"c\"}",
		expected = "d",
	})
}

@(test)
test_spec_interpolation_implicit_iterators_basic_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Implicit Iterators - Basic Interpolation",
		template = "Hello, {{.}}!\n",
		data     = "\"world\"",
		expected = "Hello, world!\n",
	})
}

@(test)
test_spec_interpolation_implicit_iterators_html_escaping :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Implicit Iterators - HTML Escaping",
		template = "These characters should be HTML escaped: {{.}}\n",
		data     = "\"& \\\" < >\"",
		expected = "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
	})
}

@(test)
test_spec_interpolation_implicit_iterators_triple_mustache :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Implicit Iterators - Triple Mustache",
		template = "These characters should not be HTML escaped: {{{.}}}\n",
		data     = "\"& \\\" < >\"",
		expected = "These characters should not be HTML escaped: & \" < >\n",
	})
}

@(test)
test_spec_interpolation_implicit_iterators_ampersand :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Implicit Iterators - Ampersand",
		template = "These characters should not be HTML escaped: {{&.}}\n",
		data     = "\"& \\\" < >\"",
		expected = "These characters should not be HTML escaped: & \" < >\n",
	})
}

@(test)
test_spec_interpolation_implicit_iterators_basic_integer_interpolation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Implicit Iterators - Basic Integer Interpolation",
		template = "\"{{.}} miles an hour!\"",
		data     = "85",
		expected = "\"85 miles an hour!\"",
	})
}

@(test)
test_spec_interpolation_interpolation_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Interpolation - Surrounding Whitespace",
		template = "| {{string}} |",
		data     = "{\"string\": \"---\"}",
		expected = "| --- |",
	})
}

@(test)
test_spec_interpolation_triple_mustache_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache - Surrounding Whitespace",
		template = "| {{{string}}} |",
		data     = "{\"string\": \"---\"}",
		expected = "| --- |",
	})
}

@(test)
test_spec_interpolation_ampersand_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand - Surrounding Whitespace",
		template = "| {{&string}} |",
		data     = "{\"string\": \"---\"}",
		expected = "| --- |",
	})
}

@(test)
test_spec_interpolation_interpolation_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Interpolation - Standalone",
		template = "  {{string}}\n",
		data     = "{\"string\": \"---\"}",
		expected = "  ---\n",
	})
}

@(test)
test_spec_interpolation_triple_mustache_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache - Standalone",
		template = "  {{{string}}}\n",
		data     = "{\"string\": \"---\"}",
		expected = "  ---\n",
	})
}

@(test)
test_spec_interpolation_ampersand_standalone :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand - Standalone",
		template = "  {{&string}}\n",
		data     = "{\"string\": \"---\"}",
		expected = "  ---\n",
	})
}

@(test)
test_spec_interpolation_interpolation_with_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Interpolation With Padding",
		template = "|{{ string }}|",
		data     = "{\"string\": \"---\"}",
		expected = "|---|",
	})
}

@(test)
test_spec_interpolation_triple_mustache_with_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Triple Mustache With Padding",
		template = "|{{{ string }}}|",
		data     = "{\"string\": \"---\"}",
		expected = "|---|",
	})
}

@(test)
test_spec_interpolation_ampersand_with_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "interpolation: Ampersand With Padding",
		template = "|{{& string }}|",
		data     = "{\"string\": \"---\"}",
		expected = "|---|",
	})
}

@(test)
test_spec_inverted_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Falsey",
		template = "\"{{^boolean}}This should be rendered.{{/boolean}}\"",
		data     = "{\"boolean\": false}",
		expected = "\"This should be rendered.\"",
	})
}

@(test)
test_spec_inverted_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Truthy",
		template = "\"{{^boolean}}This should not be rendered.{{/boolean}}\"",
		data     = "{\"boolean\": true}",
		expected = "\"\"",
	})
}

@(test)
test_spec_inverted_null_is_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Null is falsey",
		template = "\"{{^null}}This should be rendered.{{/null}}\"",
		data     = "{\"null\": null}",
		expected = "\"This should be rendered.\"",
	})
}

@(test)
test_spec_inverted_context :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Context",
		template = "\"{{^context}}Hi {{name}}.{{/context}}\"",
		data     = "{\"context\": {\"name\": \"Joe\"}}",
		expected = "\"\"",
	})
}

@(test)
test_spec_inverted_list :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: List",
		template = "\"{{^list}}{{n}}{{/list}}\"",
		data     = "{\"list\": [{\"n\": 1}, {\"n\": 2}, {\"n\": 3}]}",
		expected = "\"\"",
	})
}

@(test)
test_spec_inverted_empty_list :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Empty List",
		template = "\"{{^list}}Yay lists!{{/list}}\"",
		data     = "{\"list\": []}",
		expected = "\"Yay lists!\"",
	})
}

@(test)
test_spec_inverted_doubled :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Doubled",
		template = "{{^bool}}\n* first\n{{/bool}}\n* {{two}}\n{{^bool}}\n* third\n{{/bool}}\n",
		data     = "{\"bool\": false, \"two\": \"second\"}",
		expected = "* first\n* second\n* third\n",
	})
}

@(test)
test_spec_inverted_nested_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Nested (Falsey)",
		template = "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |",
		data     = "{\"bool\": false}",
		expected = "| A B C D E |",
	})
}

@(test)
test_spec_inverted_nested_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Nested (Truthy)",
		template = "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |",
		data     = "{\"bool\": true}",
		expected = "| A  E |",
	})
}

@(test)
test_spec_inverted_context_misses :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Context Misses",
		template = "[{{^missing}}Cannot find key 'missing'!{{/missing}}]",
		data     = "{}",
		expected = "[Cannot find key 'missing'!]",
	})
}

@(test)
test_spec_inverted_dotted_names_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Dotted Names - Truthy",
		template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"\"",
		data     = "{\"a\": {\"b\": {\"c\": true}}}",
		expected = "\"\" == \"\"",
	})
}

@(test)
test_spec_inverted_dotted_names_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Dotted Names - Falsey",
		template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\"",
		data     = "{\"a\": {\"b\": {\"c\": false}}}",
		expected = "\"Not Here\" == \"Not Here\"",
	})
}

@(test)
test_spec_inverted_dotted_names_broken_chains :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Dotted Names - Broken Chains",
		template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\"",
		data     = "{\"a\": {}}",
		expected = "\"Not Here\" == \"Not Here\"",
	})
}

@(test)
test_spec_inverted_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Surrounding Whitespace",
		template = " | {{^boolean}}\t|\t{{/boolean}} | \n",
		data     = "{\"boolean\": false}",
		expected = " | \t|\t | \n",
	})
}

@(test)
test_spec_inverted_internal_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Internal Whitespace",
		template = " | {{^boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n",
		data     = "{\"boolean\": false}",
		expected = " |  \n  | \n",
	})
}

@(test)
test_spec_inverted_indented_inline_sections :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Indented Inline Sections",
		template = " {{^boolean}}NO{{/boolean}}\n {{^boolean}}WAY{{/boolean}}\n",
		data     = "{\"boolean\": false}",
		expected = " NO\n WAY\n",
	})
}

@(test)
test_spec_inverted_standalone_lines :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Standalone Lines",
		template = "| This Is\n{{^boolean}}\n|\n{{/boolean}}\n| A Line\n",
		data     = "{\"boolean\": false}",
		expected = "| This Is\n|\n| A Line\n",
	})
}

@(test)
test_spec_inverted_standalone_indented_lines :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Standalone Indented Lines",
		template = "| This Is\n  {{^boolean}}\n|\n  {{/boolean}}\n| A Line\n",
		data     = "{\"boolean\": false}",
		expected = "| This Is\n|\n| A Line\n",
	})
}

@(test)
test_spec_inverted_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Standalone Line Endings",
		template = "|\r\n{{^boolean}}\r\n{{/boolean}}\r\n|",
		data     = "{\"boolean\": false}",
		expected = "|\r\n|",
	})
}

@(test)
test_spec_inverted_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Standalone Without Previous Line",
		template = "  {{^boolean}}\n^{{/boolean}}\n/",
		data     = "{\"boolean\": false}",
		expected = "^\n/",
	})
}

@(test)
test_spec_inverted_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Standalone Without Newline",
		template = "^{{^boolean}}\n/\n  {{/boolean}}",
		data     = "{\"boolean\": false}",
		expected = "^\n/\n",
	})
}

@(test)
test_spec_inverted_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "inverted: Padding",
		template = "|{{^ boolean }}={{/ boolean }}|",
		data     = "{\"boolean\": false}",
		expected = "|=|",
	})
}

@(test)
test_spec_partials_basic_behavior :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Basic Behavior",
		template = "\"{{>text}}\"",
		data     = "{}",
		partials = {
			{"text", "from partial"},
		},
		expected = "\"from partial\"",
	})
}

@(test)
test_spec_partials_failed_lookup :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Failed Lookup",
		template = "\"{{>text}}\"",
		data     = "{}",
		expected = "\"\"",
	})
}

@(test)
test_spec_partials_context :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Context",
		template = "\"{{>partial}}\"",
		data     = "{\"text\": \"content\"}",
		partials = {
			{"partial", "*{{text}}*"},
		},
		expected = "\"*content*\"",
	})
}

@(test)
test_spec_partials_recursion :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Recursion",
		template = "{{>node}}",
		data     = "{\"content\": \"X\", \"nodes\": [{\"content\": \"Y\", \"nodes\": []}]}",
		partials = {
			{"node", "{{content}}<{{#nodes}}{{>node}}{{/nodes}}>"},
		},
		expected = "X<Y<>>",
	})
}

@(test)
test_spec_partials_nested :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Nested",
		template = "{{>outer}}",
		data     = "{\"a\": \"hello\", \"b\": \"world\"}",
		partials = {
			{"inner", "{{b}}!"},
			{"outer", "*{{a}} {{>inner}}*"},
		},
		expected = "*hello world!*",
	})
}

@(test)
test_spec_partials_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Surrounding Whitespace",
		template = "| {{>partial}} |",
		data     = "{}",
		partials = {
			{"partial", "\t|\t"},
		},
		expected = "| \t|\t |",
	})
}

@(test)
test_spec_partials_inline_indentation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Inline Indentation",
		template = "  {{data}}  {{> partial}}\n",
		data     = "{\"data\": \"|\"}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = "  |  >\n>\n",
	})
}

@(test)
test_spec_partials_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Standalone Line Endings",
		template = "|\r\n{{>partial}}\r\n|",
		data     = "{}",
		partials = {
			{"partial", ">"},
		},
		expected = "|\r\n>|",
	})
}

@(test)
test_spec_partials_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Standalone Without Previous Line",
		template = "  {{>partial}}\n>",
		data     = "{}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = "  >\n  >>",
	})
}

@(test)
test_spec_partials_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Standalone Without Newline",
		template = ">\n  {{>partial}}",
		data     = "{}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = ">\n  >\n  >",
	})
}

@(test)
test_spec_partials_standalone_indentation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Standalone Indentation",
		template = "\\\n {{>partial}}\n/\n",
		data     = "{\"content\": \"<\\n->\"}",
		partials = {
			{"partial", "|\n{{{content}}}\n|\n"},
		},
		expected = "\\\n |\n <\n->\n |\n/\n",
	})
}

@(test)
test_spec_partials_padding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "partials: Padding Whitespace",
		template = "|{{> partial }}|",
		data     = "{\"boolean\": true}",
		partials = {
			{"partial", "[]"},
		},
		expected = "|[]|",
	})
}

@(test)
test_spec_sections_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Truthy",
		template = "\"{{#boolean}}This should be rendered.{{/boolean}}\"",
		data     = "{\"boolean\": true}",
		expected = "\"This should be rendered.\"",
	})
}

@(test)
test_spec_sections_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Falsey",
		template = "\"{{#boolean}}This should not be rendered.{{/boolean}}\"",
		data     = "{\"boolean\": false}",
		expected = "\"\"",
	})
}

@(test)
test_spec_sections_null_is_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Null is falsey",
		template = "\"{{#null}}This should not be rendered.{{/null}}\"",
		data     = "{\"null\": null}",
		expected = "\"\"",
	})
}

@(test)
test_spec_sections_context :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Context",
		template = "\"{{#context}}Hi {{name}}.{{/context}}\"",
		data     = "{\"context\": {\"name\": \"Joe\"}}",
		expected = "\"Hi Joe.\"",
	})
}

@(test)
test_spec_sections_parent_contexts :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Parent contexts",
		template = "\"{{#sec}}{{a}}, {{b}}, {{c.d}}{{/sec}}\"",
		data     = "{\"a\": \"foo\", \"b\": \"wrong\", \"c\": {\"d\": \"baz\"}, \"sec\": {\"b\": \"bar\"}}",
		expected = "\"foo, bar, baz\"",
	})
}

@(test)
test_spec_sections_variable_test :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Variable test",
		template = "\"{{#foo}}{{.}} is {{foo}}{{/foo}}\"",
		data     = "{\"foo\": \"bar\"}",
		expected = "\"bar is bar\"",
	})
}

@(test)
test_spec_sections_list_contexts :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: List Contexts",
		template = "{{#tops}}{{#middles}}{{tname.lower}}{{mname}}.{{#bottoms}}{{tname.upper}}{{mname}}{{bname}}.{{/bottoms}}{{/middles}}{{/tops}}",
		data     = "{\"tops\": [{\"middles\": [{\"bottoms\": [{\"bname\": \"x\"}, {\"bname\": \"y\"}], \"mname\": \"1\"}], \"tname\": {\"lower\": \"a\", \"upper\": \"A\"}}]}",
		expected = "a1.A1x.A1y.",
	})
}

@(test)
test_spec_sections_deeply_nested_contexts :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Deeply Nested Contexts",
		template = "{{#a}}\n{{one}}\n{{#b}}\n{{one}}{{two}}{{one}}\n{{#c}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{#d}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{#five}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{.}}6{{.}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{/five}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{/d}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{/c}}\n{{one}}{{two}}{{one}}\n{{/b}}\n{{one}}\n{{/a}}\n",
		data     = "{\"a\": {\"one\": 1}, \"b\": {\"two\": 2}, \"c\": {\"d\": {\"five\": 5, \"four\": 4}, \"three\": 3}}",
		expected = "1\n121\n12321\n1234321\n123454321\n12345654321\n123454321\n1234321\n12321\n121\n1\n",
	})
}

@(test)
test_spec_sections_list :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: List",
		template = "\"{{#list}}{{item}}{{/list}}\"",
		data     = "{\"list\": [{\"item\": 1}, {\"item\": 2}, {\"item\": 3}]}",
		expected = "\"123\"",
	})
}

@(test)
test_spec_sections_empty_list :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Empty List",
		template = "\"{{#list}}Yay lists!{{/list}}\"",
		data     = "{\"list\": []}",
		expected = "\"\"",
	})
}

@(test)
test_spec_sections_doubled :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Doubled",
		template = "{{#bool}}\n* first\n{{/bool}}\n* {{two}}\n{{#bool}}\n* third\n{{/bool}}\n",
		data     = "{\"bool\": true, \"two\": \"second\"}",
		expected = "* first\n* second\n* third\n",
	})
}

@(test)
test_spec_sections_nested_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Nested (Truthy)",
		template = "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |",
		data     = "{\"bool\": true}",
		expected = "| A B C D E |",
	})
}

@(test)
test_spec_sections_nested_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Nested (Falsey)",
		template = "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |",
		data     = "{\"bool\": false}",
		expected = "| A  E |",
	})
}

@(test)
test_spec_sections_context_misses :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Context Misses",
		template = "[{{#missing}}Found key 'missing'!{{/missing}}]",
		data     = "{}",
		expected = "[]",
	})
}

@(test)
test_spec_sections_implicit_iterator_string :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - String",
		template = "\"{{#list}}({{.}}){{/list}}\"",
		data     = "{\"list\": [\"a\", \"b\", \"c\", \"d\", \"e\"]}",
		expected = "\"(a)(b)(c)(d)(e)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_integer :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Integer",
		template = "\"{{#list}}({{.}}){{/list}}\"",
		data     = "{\"list\": [1, 2, 3, 4, 5]}",
		expected = "\"(1)(2)(3)(4)(5)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_decimal :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Decimal",
		template = "\"{{#list}}({{.}}){{/list}}\"",
		data     = "{\"list\": [1.1, 2.2, 3.3, 4.4, 5.5]}",
		expected = "\"(1.1)(2.2)(3.3)(4.4)(5.5)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_array :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Array",
		template = "\"{{#list}}({{#.}}{{.}}{{/.}}){{/list}}\"",
		data     = "{\"list\": [[1, 2, 3], [\"a\", \"b\", \"c\"]]}",
		expected = "\"(123)(abc)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_html_escaping :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - HTML Escaping",
		template = "\"{{#list}}({{.}}){{/list}}\"",
		data     = "{\"list\": [\"&\", \"\\\"\", \"<\", \">\"]}",
		expected = "\"(&amp;)(&quot;)(&lt;)(&gt;)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_triple_mustache :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Triple mustache",
		template = "\"{{#list}}({{{.}}}){{/list}}\"",
		data     = "{\"list\": [\"&\", \"\\\"\", \"<\", \">\"]}",
		expected = "\"(&)(\")(<)(>)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_ampersand :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Ampersand",
		template = "\"{{#list}}({{&.}}){{/list}}\"",
		data     = "{\"list\": [\"&\", \"\\\"\", \"<\", \">\"]}",
		expected = "\"(&)(\")(<)(>)\"",
	})
}

@(test)
test_spec_sections_implicit_iterator_root_level :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Implicit Iterator - Root-level",
		template = "\"{{#.}}({{value}}){{/.}}\"",
		data     = "[{\"value\": \"a\"}, {\"value\": \"b\"}]",
		expected = "\"(a)(b)\"",
	})
}

@(test)
test_spec_sections_dotted_names_truthy :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Dotted Names - Truthy",
		template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"Here\"",
		data     = "{\"a\": {\"b\": {\"c\": true}}}",
		expected = "\"Here\" == \"Here\"",
	})
}

@(test)
test_spec_sections_dotted_names_falsey :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Dotted Names - Falsey",
		template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\"",
		data     = "{\"a\": {\"b\": {\"c\": false}}}",
		expected = "\"\" == \"\"",
	})
}

@(test)
test_spec_sections_dotted_names_broken_chains :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Dotted Names - Broken Chains",
		template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\"",
		data     = "{\"a\": {}}",
		expected = "\"\" == \"\"",
	})
}

@(test)
test_spec_sections_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Surrounding Whitespace",
		template = " | {{#boolean}}\t|\t{{/boolean}} | \n",
		data     = "{\"boolean\": true}",
		expected = " | \t|\t | \n",
	})
}

@(test)
test_spec_sections_internal_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Internal Whitespace",
		template = " | {{#boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n",
		data     = "{\"boolean\": true}",
		expected = " |  \n  | \n",
	})
}

@(test)
test_spec_sections_indented_inline_sections :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Indented Inline Sections",
		template = " {{#boolean}}YES{{/boolean}}\n {{#boolean}}GOOD{{/boolean}}\n",
		data     = "{\"boolean\": true}",
		expected = " YES\n GOOD\n",
	})
}

@(test)
test_spec_sections_standalone_lines :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Standalone Lines",
		template = "| This Is\n{{#boolean}}\n|\n{{/boolean}}\n| A Line\n",
		data     = "{\"boolean\": true}",
		expected = "| This Is\n|\n| A Line\n",
	})
}

@(test)
test_spec_sections_indented_standalone_lines :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Indented Standalone Lines",
		template = "| This Is\n  {{#boolean}}\n|\n  {{/boolean}}\n| A Line\n",
		data     = "{\"boolean\": true}",
		expected = "| This Is\n|\n| A Line\n",
	})
}

@(test)
test_spec_sections_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Standalone Line Endings",
		template = "|\r\n{{#boolean}}\r\n{{/boolean}}\r\n|",
		data     = "{\"boolean\": true}",
		expected = "|\r\n|",
	})
}

@(test)
test_spec_sections_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Standalone Without Previous Line",
		template = "  {{#boolean}}\n#{{/boolean}}\n/",
		data     = "{\"boolean\": true}",
		expected = "#\n/",
	})
}

@(test)
test_spec_sections_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Standalone Without Newline",
		template = "#{{#boolean}}\n/\n  {{/boolean}}",
		data     = "{\"boolean\": true}",
		expected = "#\n/\n",
	})
}

@(test)
test_spec_sections_padding :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "sections: Padding",
		template = "|{{# boolean }}={{/ boolean }}|",
		data     = "{\"boolean\": true}",
		expected = "|=|",
	})
}

@(test)
test_spec_dynamic_names_basic_behavior_partial :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Basic Behavior - Partial",
		template = "\"{{>*dynamic}}\"",
		data     = "{\"dynamic\": \"content\"}",
		partials = {
			{"content", "Hello, world!"},
		},
		expected = "\"Hello, world!\"",
	})
}

@(test)
test_spec_dynamic_names_basic_behavior_name_resolution :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Basic Behavior - Name Resolution",
		template = "\"{{>*dynamic}}\"",
		data     = "{\"*dynamic\": \"wrong\", \"dynamic\": \"content\"}",
		partials = {
			{"content", "Hello, world!"},
			{"wrong", "Invisible"},
		},
		expected = "\"Hello, world!\"",
	})
}

@(test)
test_spec_dynamic_names_context_misses_partial :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Context Misses - Partial",
		template = "\"{{>*missing}}\"",
		data     = "{}",
		partials = {
			{"missing", "Hello, world!"},
		},
		expected = "\"\"",
	})
}

@(test)
test_spec_dynamic_names_failed_lookup_partial :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Failed Lookup - Partial",
		template = "\"{{>*dynamic}}\"",
		data     = "{\"dynamic\": \"content\"}",
		partials = {
			{"foobar", "Hello, world!"},
		},
		expected = "\"\"",
	})
}

@(test)
test_spec_dynamic_names_context :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Context",
		template = "\"{{>*example}}\"",
		data     = "{\"example\": \"partial\", \"text\": \"Hello, world!\"}",
		partials = {
			{"partial", "*{{text}}*"},
		},
		expected = "\"*Hello, world!*\"",
	})
}

@(test)
test_spec_dynamic_names_dotted_names :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted Names",
		template = "\"{{>*foo.bar.baz}}\"",
		data     = "{\"foo\": {\"bar\": {\"baz\": \"partial\"}}, \"text\": \"Hello, world!\"}",
		partials = {
			{"partial", "*{{text}}*"},
		},
		expected = "\"*Hello, world!*\"",
	})
}

@(test)
test_spec_dynamic_names_dotted_names_operator_precedence :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted Names - Operator Precedence",
		template = "\"{{>*foo.bar.baz}}\"",
		data     = "{\"foo\": \"test\", \"test\": {\"bar\": {\"baz\": \"partial\"}}, \"text\": \"Hello, world!\"}",
		partials = {
			{"partial", "*{{text}}*"},
		},
		expected = "\"\"",
	})
}

@(test)
test_spec_dynamic_names_dotted_names_failed_lookup :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted Names - Failed Lookup",
		template = "\"{{>*foo.bar.baz}}\"",
		data     = "{\"foo\": {\"bar\": {\"baz\": \"partial\"}, \"text\": \"Hello, world!\"}}",
		partials = {
			{"partial", "*{{text}}*"},
		},
		expected = "\"**\"",
	})
}

@(test)
test_spec_dynamic_names_dotted_names_context_stacking :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted names - Context Stacking",
		template = "{{#section1}}{{>*section2.dynamic}}{{/section1}}",
		data     = "{\"section1\": {\"value\": \"section1\"}, \"section2\": {\"dynamic\": \"partial\", \"value\": \"section2\"}}",
		partials = {
			{"partial", "\"{{value}}\""},
		},
		expected = "\"section1\"",
	})
}

@(test)
test_spec_dynamic_names_dotted_names_context_stacking_under_repetition :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted names - Context Stacking Under Repetition",
		template = "{{#section1}}{{>*section2.dynamic}}{{/section1}}",
		data     = "{\"section1\": [1, 2], \"section2\": {\"dynamic\": \"partial\", \"value\": \"section2\"}, \"value\": \"test\"}",
		partials = {
			{"partial", "{{value}}"},
		},
		expected = "testtest",
	})
}

@(test)
test_spec_dynamic_names_dotted_names_context_stacking_failed_lookup :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dotted names - Context Stacking Failed Lookup",
		template = "{{#section1}}{{>*section2.dynamic}}{{/section1}}",
		data     = "{\"section1\": [1, 2], \"section2\": {\"dynamic\": \"partial\", \"value\": \"section2\"}}",
		partials = {
			{"partial", "\"{{value}}\""},
		},
		expected = "\"\"\"\"",
	})
}

@(test)
test_spec_dynamic_names_recursion :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Recursion",
		template = "{{>*template}}",
		data     = "{\"content\": \"X\", \"nodes\": [{\"content\": \"Y\", \"nodes\": []}], \"template\": \"node\"}",
		partials = {
			{"node", "{{content}}<{{#nodes}}{{>*template}}{{/nodes}}>"},
		},
		expected = "X<Y<>>",
	})
}

@(test)
test_spec_dynamic_names_dynamic_names_double_dereferencing :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dynamic Names - Double Dereferencing",
		template = "\"{{>**dynamic}}\"",
		data     = "{\"dynamic\": \"test\", \"test\": \"content\"}",
		partials = {
			{"content", "Hello, world!"},
		},
		expected = "\"\"",
	})
}

@(test)
test_spec_dynamic_names_dynamic_names_composed_dereferencing :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Dynamic Names - Composed Dereferencing",
		template = "\"{{>*foo.*bar}}\"",
		data     = "{\"bar\": \"buzz\", \"fizz\": {\"buzz\": {\"content\": null}}, \"foo\": \"fizz\"}",
		partials = {
			{"content", "Hello, world!"},
		},
		expected = "\"\"",
	})
}

@(test)
test_spec_dynamic_names_surrounding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Surrounding Whitespace",
		template = "| {{>*partial}} |",
		data     = "{\"partial\": \"foobar\"}",
		partials = {
			{"foobar", "\t|\t"},
		},
		expected = "| \t|\t |",
	})
}

@(test)
test_spec_dynamic_names_inline_indentation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Inline Indentation",
		template = "  {{data}}  {{>*dynamic}}\n",
		data     = "{\"data\": \"|\", \"dynamic\": \"partial\"}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = "  |  >\n>\n",
	})
}

@(test)
test_spec_dynamic_names_standalone_line_endings :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Standalone Line Endings",
		template = "|\r\n{{>*dynamic}}\r\n|",
		data     = "{\"dynamic\": \"partial\"}",
		partials = {
			{"partial", ">"},
		},
		expected = "|\r\n>|",
	})
}

@(test)
test_spec_dynamic_names_standalone_without_previous_line :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Standalone Without Previous Line",
		template = "  {{>*dynamic}}\n>",
		data     = "{\"dynamic\": \"partial\"}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = "  >\n  >>",
	})
}

@(test)
test_spec_dynamic_names_standalone_without_newline :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Standalone Without Newline",
		template = ">\n  {{>*dynamic}}",
		data     = "{\"dynamic\": \"partial\"}",
		partials = {
			{"partial", ">\n>"},
		},
		expected = ">\n  >\n  >",
	})
}

@(test)
test_spec_dynamic_names_standalone_indentation :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Standalone Indentation",
		template = "\\\n {{>*dynamic}}\n/\n",
		data     = "{\"content\": \"<\\n->\", \"dynamic\": \"partial\"}",
		partials = {
			{"partial", "|\n{{{content}}}\n|\n"},
		},
		expected = "\\\n |\n <\n->\n |\n/\n",
	})
}

@(test)
test_spec_dynamic_names_padding_whitespace :: proc(t: ^testing.T) {
	run_spec_case(t, Spec_Case{
		name     = "~dynamic-names: Padding Whitespace",
		template = "|{{> * dynamic }}|",
		data     = "{\"boolean\": true, \"dynamic\": \"partial\"}",
		partials = {
			{"partial", "[]"},
		},
		expected = "|[]|",
	})
}
