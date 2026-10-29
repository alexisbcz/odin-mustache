// Example basic renders a small HTML list from literal data and a partial. Run it with `odin run examples/basic`.
package main

import mustache "../.."
import "core:fmt"
import "core:os"

PAGE :: `<h1>{{title}}</h1>
{{#items}}
  {{> item}}
{{/items}}
{{^items}}
  <p>Nothing to show.</p>
{{/items}}
`

ITEM :: `<li>{{name}}{{#beta}} (beta){{/beta}}</li>
`

main :: proc() {
	partials: mustache.Partials
	mustache.partials_init(&partials)
	defer mustache.partials_destroy(&partials)
	if err := mustache.partials_add(&partials, "item", ITEM); err != nil {
		fmt.eprintln("bad partial:", err)
		os.exit(1)
	}

	page, loc, err := mustache.compile_with_location(PAGE)
	if err != nil {
		fmt.eprintfln("bad template at line %d, column %d: %v", loc.line, loc.column, err)
		os.exit(1)
	}
	defer mustache.template_destroy(&page)

	data := mustache.Object {
		{"title", "Odin libraries <2026>"},
		{"items", mustache.List {
			mustache.Object{{"name", "odin-mustache"}},
			mustache.Object{{"name", "odin-http"}, {"beta", true}},
		}},
	}
	out, rerr := mustache.render(page, data, &partials)
	if rerr != nil {
		fmt.eprintln("render failed:", rerr)
		os.exit(1)
	}
	defer delete(out)
	fmt.print(out)
}
