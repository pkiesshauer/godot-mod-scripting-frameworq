extends RefCounted
class_name Function

var name: String
var start_line: int
var instructions: Array[Instruction]
var else_map: Dictionary[int, int]
var endif_map: Dictionary[int, int]
var while_end_map: Dictionary[int, int]
var end_while_map: Dictionary[int, int]

func _to_string() -> String:
	var text: String = "FUNC " + name
	text += "\n"
	for i in instructions.size():
		text += str(i) + "/" + instructions[i].to_string()
		text += "\n"
	text += str(else_map)
	text += "\n"
	text += str(endif_map)
	text += "\n"
	text += str(while_end_map)
	text += "\n"
	text += str(end_while_map)
	text += "\n"
	return text
