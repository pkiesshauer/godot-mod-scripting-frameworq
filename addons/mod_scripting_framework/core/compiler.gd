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
const KW_WAIT: String = "wait"

func compile(script: String) -> Program:
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
			var func_name: String = text_line.substr(KW_FUNC.length()).strip_edges()
			if func_name == "": return compile_error(program, "Missing function name", script_line)
			if program.functions.keys().has(func_name): return compile_error(program, "Function name duplicate", script_line)
			current_func = Function.new()
			current_func.name = func_name
			current_func.start_line = script_line+1
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
		#elif text_line.begins_with(KW_WAIT):
			#var instruction: Instruction = Instruction.new()
			#instruction.script_line = script_line
			#instruction.type = Constants.InstructionType.WAIT
			#var exp = text_line.substr(KW_WAIT.length()).strip_edges()
			#if not exp.is_valid_int(): return compile_error(program, "Argument for 'wait' is not an integer", script_line)
			#instruction.expression = exp
			#current_func.instructions.push_back(instruction)
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

func compile_error(program, message, line) -> Program:
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

func is_valid_identifier(identifier: String) -> bool:
	for i in range(identifier.length()):
		if i == 0:
			if not var_name_begin.contains(identifier[i]): return false
		else:
			if not var_name_chars.contains(identifier[i]): return false
	return true
