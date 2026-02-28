extends RefCounted
class_name Function

var name: String
var start_line: int
var instructions: Array[Instruction]
var else_map: Dictionary[int, int]
var endif_map: Dictionary[int, int]
var while_end_map: Dictionary[int, int]
var end_while_map: Dictionary[int, int]

var parameters: Array[String]
var defaults: Dictionary[String, String]

func has_parameters() -> bool:
	return parameters.size() > 0

func _to_string() -> String:
	var text: String = "FUNC " + name + "("
	for p in parameters:
		if defaults.has(p):
			text += "%s = %s, " % [p, defaults[p]]
		else:
			text += p + ", "
	if parameters.size() > 0:
		text = text.substr(0, text.length() - 2) + ")"
	text += "\n"
	for i in instructions.size():
		text += str(i) + "/" + instructions[i].to_string()
		text += "\n"
	text += str(parameters)
	text += "\n"
	text += str(defaults)
	text += "\n"
	return text
