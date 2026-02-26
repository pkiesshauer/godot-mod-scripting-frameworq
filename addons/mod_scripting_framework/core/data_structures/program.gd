extends RefCounted
class_name Program

var functions: Dictionary [String, Function]
var error: Error = OK
var error_message: String
var source: String
var globals: Dictionary [String, Variant]


func _to_string() -> String:
	var text: String
	for f in functions.keys():
		text += functions[f].to_string()
	return text

func duplicate_globals() -> Dictionary:
	return globals.duplicate()

func has_function(function_name) -> bool:
	return functions.has(function_name)
