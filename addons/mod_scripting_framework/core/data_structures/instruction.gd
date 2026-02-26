extends RefCounted
class_name Instruction

var script_line: int
var type: Constants.InstructionType
var variable_name: String
var expression: String
var parameters: Dictionary[String, String]

func _to_string() -> String:
	if type == Constants.InstructionType.ASSIGN:
		return "%s: %s %s = %s" % [script_line, Constants.InstructionType.keys()[type], variable_name, expression]
	elif type == Constants.InstructionType.CALL:
		var string = "%s: %s (" % [script_line, Constants.InstructionType.keys()[type]]
		for p in parameters:
			string += "%s = %s" % [p, parameters[p]]
			string += ", "
		string = string.substr(0, string.length()-2)
		string += ")"
		return string
	else:
		return "%s: %s %s" % [script_line, Constants.InstructionType.keys()[type], expression]
