// Example json renders a template straight from a core:encoding/json value. Run it with `odin run examples/json`.
package main

import mustache "../.."
import "core:encoding/json"
import "core:fmt"
import "core:os"

DATA :: `{
	"user": {"name": "Ada", "unread": 3},
	"messages": [
		{"from": "Grace", "subject": "Compilers & you"},
		{"from": "Linus", "subject": "Re: patches"}
	]
}`

main :: proc() {
	data, jerr := json.parse_string(DATA, parse_integers = true)
	if jerr != nil {
		fmt.eprintln("bad JSON:", jerr)
		os.exit(1)
	}
	defer json.destroy_value(data)

	tmpl, err := mustache.compile("Hi {{user.name}}, you have {{user.unread}} unread messages:\n{{#messages}}- {{subject}} (from {{from}})\n{{/messages}}")
	if err != nil {
		fmt.eprintln("bad template:", err)
		os.exit(1)
	}
	defer mustache.template_destroy(&tmpl)

	out, rerr := mustache.render_json(tmpl, data)
	if rerr != nil {
		fmt.eprintln("render failed:", rerr)
		os.exit(1)
	}
	defer delete(out)
	fmt.print(out)
}
