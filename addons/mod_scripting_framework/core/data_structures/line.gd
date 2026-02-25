extends RefCounted
class_name Instruction

var script_line: int
var type: Constants.InstructionType
var variable_name: String
var expression: String

func _to_string() -> String:
	if type == Constants.InstructionType.ASSIGN:
		return "%s: %s %s = %s" % [script_line, Constants.InstructionType.keys()[type], variable_name, expression]
	else:
		return "%s: %s %s" % [script_line, Constants.InstructionType.keys()[type], expression]
