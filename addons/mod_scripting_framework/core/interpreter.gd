extends RefCounted
class_name Interpreter

signal error(error_message: String)

var program: Program
var mod_api: ModAPI

var max_instruction_count: int = 100000

var _execute_error: bool

func setup(p: Program, api: ModAPI):
	program = p
	mod_api = api

func run_function(name: String) -> bool:
	if not program.has_function(name):
		return true
	_execute_error = false
	var local_context: Dictionary = program.duplicate_globals()
	var function: Function = program.functions[name]
	execute_function(function, local_context)
	return _execute_error

func run_function_internal(name: String, local_context: Dictionary):
	if not program.has_function(name):
		return
	var merge = program.duplicate_globals()
	merge.merge(local_context, true)
	var function: Function = program.functions[name]
	execute_function(function, merge)

func execute_function(function: Function, local_context: Dictionary):
	var instruction_pointer: int = 0
	var instruction_count: int = 0
	while instruction_pointer < function.instructions.size() and instruction_count < max_instruction_count:
		var instr:Instruction = function.instructions[instruction_pointer]
		instruction_pointer = execute_instruction(function, instr, instruction_pointer, local_context)
		instruction_count += 1

func execute_instruction(function: Function, instruction: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	match instruction.type:
		Constants.InstructionType.IF: return exec_if(function, instruction, instruction_pointer, local_context)
		Constants.InstructionType.ELSE: return function.endif_map[instruction_pointer] + 1
		Constants.InstructionType.END_IF: return instruction_pointer + 1
		Constants.InstructionType.WHILE: return exec_while(function, instruction, instruction_pointer, local_context)
		Constants.InstructionType.END_WHILE: return function.end_while_map[instruction_pointer]
		Constants.InstructionType.ASSIGN:
			exec_assign(instruction, local_context)
			return instruction_pointer + 1
		Constants.InstructionType.EXPRESSION:
			eval_expression(instruction.expression, instruction.script_line, local_context)
			return instruction_pointer + 1
		Constants.InstructionType.CALL:
			var parameters: Dictionary = eval_parameters(function, instruction, local_context)
			print(parameters)
			run_function_internal(instruction.expression, parameters)
			return instruction_pointer + 1
	return instruction_pointer + 1

func exec_if(function: Function, instruction: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	var result = eval_expression(instruction.expression, instruction.script_line, local_context)
	if result:
		return instruction_pointer + 1
	else:
		return function.else_map[instruction_pointer] + 1

func exec_while(function: Function, instruction: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	var result = eval_expression(instruction.expression, instruction.script_line, local_context)
	if result:
		return instruction_pointer + 1
	else:
		return function.while_end_map[instruction_pointer] + 1

func exec_assign(instruction: Instruction, local_context: Dictionary):
	var value = eval_expression(instruction.expression, instruction.script_line, local_context)
	local_context[instruction.variable_name] = value
	if program.globals.has(instruction.variable_name):
		program.globals[instruction.variable_name] = value

func eval_parameters(function: Function, instruction: Instruction, local_context: Dictionary) -> Dictionary:
	var result: Dictionary
	var target_function: Function = program.functions[instruction.expression]
	for d in target_function.defaults:
		result[d] = eval_expression(target_function.defaults[d], instruction.script_line, local_context)
	for p in instruction.parameters:
		result[p] = eval_expression(instruction.parameters[p], instruction.script_line, local_context)
	return result

func eval_expression(expression_text: String, script_line: int, local_context: Dictionary):
	var expression = Expression.new()
	var merge_context: Dictionary = mod_api.context.duplicate(true)
	merge_context.merge(local_context, true)
	var err = expression.parse(expression_text, merge_context.keys())
	if err != OK:
		_execute_error = true
		error.emit("Expression parse error on line %s: %s" % [script_line+1, expression.get_error_text()])
		return null
	var result = expression.execute(merge_context.values(), mod_api)
	if expression.has_execute_failed():
		_execute_error = true
		error.emit("Expression parse error on line %s: %s" % [script_line+1, expression.get_error_text()])
		return null
	else:
		return result
