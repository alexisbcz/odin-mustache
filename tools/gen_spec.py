"""Generates tests/spec_test.odin from the Mustache specification JSON files.

Usage:
    git clone --depth 1 --branch v1.4.3 https://github.com/mustache/spec /tmp/mustache-spec
    python3 tools/gen_spec.py /tmp/mustache-spec/specs tests/spec_test.odin

Lambdas and inheritance are optional modules that this package doesn't
implement, so their suites are skipped.
"""
import json, re, sys
spec_dir, out = sys.argv[1], sys.argv[2]
suites = ["comments", "delimiters", "interpolation", "inverted", "partials", "sections", "~dynamic-names"]

def lit(s):
    o = ['"']
    for ch in s:
        if ch == '\\': o.append('\\\\')
        elif ch == '"': o.append('\\"')
        elif ch == '\n': o.append('\\n')
        elif ch == '\r': o.append('\\r')
        elif ch == '\t': o.append('\\t')
        elif ord(ch) < 0x20: o.append('\\x%02x' % ord(ch))
        else: o.append(ch)
    o.append('"')
    return ''.join(o)

def ident(s):
    s = re.sub(r'[^0-9a-zA-Z]+', '_', s).strip('_').lower()
    return s

lines = [
    "// Code generated from the Mustache specification v1.4.3; DO NOT EDIT.",
    "// Source: https://github.com/mustache/spec/tree/v1.4.3/specs",
    "// Regenerate with the script described in CONTRIBUTING.md.",
    "package mustache_tests",
    "",
    "import \"core:testing\"",
    "",
]
count = 0
seen = set()
for suite in suites:
    d = json.load(open(f"{spec_dir}/{suite}.json"))
    sname = ident(suite)
    for t in d["tests"]:
        name = f"test_spec_{sname}_{ident(t['name'])}"
        base, n = name, 2
        while name in seen:
            name = f"{base}_{n}"; n += 1
        seen.add(name)
        parts = sorted((t.get("partials") or {}).items())
        lines.append("@(test)")
        lines.append(f"{name} :: proc(t: ^testing.T) {{")
        lines.append("\trun_spec_case(t, Spec_Case{")
        lines.append(f"\t\tname     = {lit(suite + ': ' + t['name'])},")
        lines.append(f"\t\ttemplate = {lit(t['template'])},")
        lines.append(f"\t\tdata     = {lit(json.dumps(t['data'], ensure_ascii=False, sort_keys=True))},")
        if parts:
            lines.append("\t\tpartials = {")
            for k, v in parts:
                lines.append(f"\t\t\t{{{lit(k)}, {lit(v)}}},")
            lines.append("\t\t},")
        lines.append(f"\t\texpected = {lit(t['expected'])},")
        lines.append("\t})")
        lines.append("}")
        lines.append("")
        count += 1
open(out, "w").write("\n".join(lines).rstrip("\n") + "\n")
print(count, "cases")
