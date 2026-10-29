package mustache

import "core:encoding/json"
import "core:strings"

/*
from_json makes a deep copy of a core:encoding/json value as a Value.
JSON objects become Maps, arrays become Lists, and every key and string is
copied, so the JSON value may be destroyed right after the call.

You don't need it to render JSON: render_json reads a json.Value in place.
Use from_json when you want to keep or extend the data as a Value.

Inputs:
- j: the JSON value to copy.
- allocator: allocates every list, map, key and string of the result.

Returns:
- v: the copy; free it with `value_destroy(v, allocator)`.
- err: an allocator error. On error, v is nil and nothing leaks.
*/
from_json :: proc(j: json.Value, allocator := context.allocator) -> (v: Value, err: Error) {
	switch x in j {
	case json.Null:
		return nil, nil
	case i64:
		return x, nil
	case f64:
		return x, nil
	case bool:
		return x, nil
	case string:
		return strings.clone(x, allocator) or_return, nil
	case json.Array:
		list := make(List, len(x), allocator) or_return
		for e, i in x {
			if list[i], err = from_json(e, allocator); err != nil {
				value_destroy(List(list[:i]), allocator)
				return nil, err
			}
		}
		return list, nil
	case json.Object:
		m := make(Map, len(x), allocator) or_return
		for key, e in x {
			k, kerr := strings.clone(key, allocator)
			if kerr != nil {
				value_destroy(m, allocator)
				return nil, kerr
			}
			val, verr := from_json(e, allocator)
			if verr != nil {
				delete(k, allocator)
				value_destroy(m, allocator)
				return nil, verr
			}
			m[k] = val
		}
		return m, nil
	}
	return nil, nil
}

/*
value_destroy frees a Value whose lists, objects, maps, keys and strings were
all allocated with `allocator`, such as the result of from_json.

Don't call it on values that point at literals or at memory you manage
yourself: an `Object{{"name", "Chris"}}` literal lives on the stack and its
strings are constants.
*/
value_destroy :: proc(v: Value, allocator := context.allocator) {
	switch x in v {
	case bool, i64, f64:
	case string:
		delete(x, allocator)
	case List:
		for e in x {
			value_destroy(e, allocator)
		}
		delete(x, allocator)
	case Object:
		for f in x {
			delete(f.key, allocator)
			value_destroy(f.value, allocator)
		}
		delete(x, allocator)
	case Map:
		for key, e in x {
			delete(key, allocator)
			value_destroy(e, allocator)
		}
		delete(x)
	}
}

