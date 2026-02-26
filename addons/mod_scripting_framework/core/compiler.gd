# compiler.gd
#
# Compiles Script into an executable Program.
#
# Compilation pipeline:
# 1. Parse functions
# 2. Build instruction lists
# 3. Resolve control flow jumps
#
# Runtime execution is handled by Interpreter.gd
#
# Supported constructs:
# - func/end func
# - if/else/end if

extends RefCounted
class_name Compiler

const var_name_chars: String = "abcdefghijklmnopqrstuvwxyzAMCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_"
const var_name_begin: String = "abcdefghijklmnopqrstuvwxyzAMCDEFGHIJKLMNOPQRSTUVWXYZ_"
const KW_FUNC: String = "func "
const KW_END_FUNC: String = "end func"
const KW_IF: String = "if "
const KW_ELSE: String = "else"
const KW_END_IF: String = "end if"
const KW_WHILE: String = "while "
const KW_END_WHILE: String = "end while"
const KW_CALL: String = "call "

func compile(script: String) -> Program:
	var program: Program = compile_pass(script)
	program = call_binding_pass(program)
	return program

func compile_pass(script: String) -> Program:
	var lines = script.split("\n")
	var program: Program = Program.new()
	program.source = script
	var current_func: Function
	var inside_func = false
	var if_stack: Array[If] = []
	var while_stack: Array[While] = []
	
	for script_line in range(lines.size()):
		var text_line = lines[script_line]
		var func_line: int = -1
		if current_func != null:
			func_line = script_line-current_func.start_line
		text_line = text_line.strip_edges()
		if text_line.begins_with(KW_FUNC):
			if inside_func: return compile_error(program, "Unexpected 'func'", script_line)
			var expression: String = text_line.substr(KW_FUNC.length()).strip_edges()
			var func_name: String = split_function_name(expression)
			if func_name == "": return compile_error(program, "Missing function name", script_line)
			if not is_valid_identifier(func_name): return compile_error(program, "Invalid function name", script_line)
			if not is_valid_parameter_list(expression): return compile_error(program, "Invalid parameter list", script_line)
			if program.functions.keys().has(func_name): return compile_error(program, "Function name duplicate", script_line)
			current_func = Function.new()
			current_func.name = func_name
			current_func.start_line = script_line+1
			current_func.parameters = split_parameter_list(expression)
			current_func.defaults = split_default_list(expression)
			inside_func = true
		elif text_line.begins_with(KW_END_FUNC):
			if text_line != KW_END_FUNC: return compile_error(program, "Unexpected text after 'end func'", script_line)
			if not inside_func: return compile_error(program, "Unexpected 'end func'", script_line)
			if if_stack.size() > 0: return compile_error(program, "Unclosed 'if' block", script_line)
			if while_stack.size() > 0: return compile_error(program, "Unclosed 'while' block", script_line)
			if current_func != null:
				program.functions[current_func.name] = current_func
				current_func = null
				if_stack = []
				while_stack = []
				inside_func = false
		elif text_line.begins_with(KW_IF):
			if not inside_func: return compile_error(program, "Unexpected 'if'", script_line)
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.IF
			instruction.expression = text_line.substr(KW_IF.length()).strip_edges()
			var new_if: If = If.new()
			new_if.if_line = func_line
			if_stack.push_back(new_if)
			current_func.instructions.push_back(instruction)
		elif text_line.begins_with(KW_ELSE):
			if text_line != KW_ELSE: return compile_error(program, "Unexpected text after 'else'", script_line)
			if not inside_func: return compile_error(program, "Unexpected 'else'", script_line)
			if if_stack.size() == 0: return compile_error(program, "Unexpected 'else'", script_line)
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.ELSE
			var current_if: If = if_stack.pop_back()
			current_if.else_line = func_line
			if_stack.push_back(current_if)
			current_func.instructions.push_back(instruction)
		elif text_line.begins_with(KW_END_IF):
			if text_line != KW_END_IF: return compile_error(program, "Unexpected text after 'end if'", script_line)
			if not inside_func: return compile_error(program, "Unexpected 'end if'", script_line)
			if if_stack.size() == 0: return compile_error(program, "Unexpected 'end if'", script_line)
			var current_if: If = if_stack.pop_back()
			current_if.endif_line = func_line
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.END_IF
			if current_if.else_line < 0:
				current_if.else_line = current_if.endif_line
			current_func.else_map[current_if.if_line] = current_if.else_line
			current_func.endif_map[current_if.else_line] = current_if.endif_line
			current_func.instructions.push_back(instruction)
		elif text_line.begins_with(KW_WHILE):
			if not inside_func: return compile_error(program, "Unexpected 'while'", script_line)
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.WHILE
			instruction.expression = text_line.substr(KW_WHILE.length()).strip_edges()
			var new_while: While = While.new()
			new_while.while_line = func_line
			while_stack.push_back(new_while)
			current_func.instructions.push_back(instruction)
		elif text_line.begins_with(KW_END_WHILE):
			if text_line != KW_END_WHILE: return compile_error(program, "Unexpected text after 'end while'", script_line)
			if not inside_func: return compile_error(program, "Unexpected 'end while'", script_line)
			if while_stack.size() == 0: return compile_error(program, "Unexpected 'end while'", script_line)
			var current_while: While = while_stack.pop_back()
			current_while.end_while_line = func_line
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.END_WHILE
			current_func.while_end_map[current_while.while_line] = current_while.end_while_line
			current_func.end_while_map[current_while.end_while_line] = current_while.while_line
			current_func.instructions.push_back(instruction)
		elif text_line.begins_with(KW_CALL):
			var instruction: Instruction = Instruction.new()
			instruction.script_line = script_line
			instruction.type = Constants.InstructionType.CALL
			var expression = text_line.substr(KW_CALL.length()).strip_edges()
			if not is_valid_parameter_list(expression, true): return compile_error(program, "Invalid parameter list", script_line)
			instruction.expression = split_function_name(expression)
			instruction.parameters = split_parameter_list_call(expression)
			current_func.instructions.push_back(instruction)
		elif text_line == "":
			pass
		else:
			var assign_pos: int = find_assignment_operator(text_line)
			if assign_pos >= 0:
				var var_name = text_line.substr(0, assign_pos).strip_edges()
				if not is_valid_identifier(var_name): return compile_error(program, "Invalid identifier", script_line)
				var expr = text_line.substr(assign_pos+1).strip_edges()
				if inside_func:
					var instruction := Instruction.new()
					instruction.type = Constants.InstructionType.ASSIGN
					instruction.variable_name = var_name
					instruction.expression = expr
					instruction.script_line = script_line
					current_func.instructions.push_back(instruction)
				else:
					if program.globals.has(var_name): return compile_error(program, "Global variable name not unique", script_line)
					if expr.is_valid_float(): program.globals[var_name] = float(expr)
					if expr.is_valid_int(): program.globals[var_name] = int(expr)
			else:
				if not inside_func: return compile_error(program, "Instruction outside function", script_line)
				var instruction: Instruction = Instruction.new()
				instruction.type = Constants.InstructionType.EXPRESSION
				instruction.expression = text_line.strip_edges()
				instruction.script_line = script_line
				current_func.instructions.push_back(instruction)
	if inside_func:
		return compile_error(program, "Missing 'end func' for '%s'" % current_func.name, lines.size()-1)
	return program

func call_binding_pass(program: Program) -> Program:
	for function_name in program.functions:
		var function: Function = program.functions[function_name]
		for instruction in function.instructions:
			if instruction.type == Constants.InstructionType.CALL:
				if not program.functions.has(instruction.expression):
					return compile_error(program, "Unknown function '%s'", instruction.script_line)
				else:
					var target_function: Function = program.functions[instruction.expression]
					for p in target_function.parameters:
						if not instruction.parameters.has(p): return compile_error(program, "Missing parameter '%s'"%p,instruction.script_line)
	return program

func compile_error(program: Program, message: String, line: int) -> Program:
	program.error = FAILED
	program.error_message = "Compile Error: %s on line %d" % [message, line+1]
	return program

func find_assignment_operator(line:String) -> int:
	for i in range(line.length()):
		if line[i] == "=":
			if i > 0 and i < line.length()-1:
				if line[i-1] != "=" and line[i+1] != "=":
					var left = line.substr(0, i).strip_edges()
					var right = line.substr(i+1).strip_edges()
					var left_quote = left.count("\"")
					var right_quote = right.count("\"")
					if left_quote % 2 == 1 and right_quote % 2 == 1:
						return -1
					return i
	return -1

func is_valid_parameter_list(expression: String, call: bool = false) -> bool:
	if is_valid_identifier(expression): return true
	var begin: int = expression.find("(")
	if not expression.ends_with(")"): return false
	if begin < 0: return false
	var trim_expression: String = expression.substr(begin+1, expression.length() - begin - 2)
	var split = trim_expression.split(",")
	var parameters: Array[String]
	for parameter in split:
		if is_valid_identifier(parameter):
			if call: return false
			continue
		var assign_pos: int = find_assignment_operator(parameter)
		if assign_pos < 0: return false
		var var_name = parameter.substr(0, assign_pos).strip_edges()
		if not is_valid_identifier(var_name): return false
		if parameters.has(var_name): return false
		parameters.push_back(parameter)
	return true

func split_default_list(expression: String) -> Dictionary[String, String]:
	var begin: int = expression.find("(")
	var trim_expression: String = expression.substr(begin+1, expression.length() - begin - 2)
	var split = trim_expression.split(",")
	var defaults: Dictionary[String, String]
	for parameter in split:
		if not is_valid_identifier(parameter):
			var assign_pos: int = find_assignment_operator(parameter)
			var parameter_name: String = parameter.substr(0, assign_pos).strip_edges()
			var parameter_expression = parameter.substr(assign_pos+1).strip_edges()
			defaults[parameter_name] = parameter_expression
	return defaults

func split_parameter_list(expression: String) -> Array[String]:
	if is_valid_identifier(expression): return []
	var begin: int = expression.find("(")
	var trim_expression: String = expression.substr(begin+1, expression.length() - begin - 2)
	var split = trim_expression.split(",")
	var parameters: Array[String]
	for parameter in split:
		var parameter_name: String = ""
		if is_valid_identifier(parameter):
			parameter_name = parameter
		else:
			var assign_pos: int = find_assignment_operator(parameter)
			parameter_name = parameter.substr(0, assign_pos).strip_edges()
		parameters.push_back(parameter_name)
	return parameters

func split_function_name(expression: String) -> String:
	if is_valid_identifier(expression): return expression
	var split = expression.split("(")
	if split.size() > 0:
		return split[0]
	return ""

func split_parameter_list_call(expression: String) -> Dictionary[String, String]:
	if is_valid_identifier(expression): return {}
	var begin: int = expression.find("(")
	var trim_expression: String = expression.substr(begin+1, expression.length() - begin - 2)
	var split = trim_expression.split(",")
	var parameters: Dictionary[String, String]
	for parameter in split:
		var assign_pos: int = find_assignment_operator(parameter)
		var parameter_name: String = parameter.substr(0, assign_pos).strip_edges()
		var parameter_expression: String =parameter.substr(assign_pos+1).strip_edges()
		parameters[parameter_name] = parameter_expression
	return parameters

func is_valid_identifier(identifier: String) -> bool:
	for i in range(identifier.length()):
		if i == 0:
			if not var_name_begin.contains(identifier[i]): return false
		else:
			if not var_name_chars.contains(identifier[i]): return false
	return true
