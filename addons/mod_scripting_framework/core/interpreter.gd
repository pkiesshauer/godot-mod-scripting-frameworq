extends RefCounted
class_name Interpreter

signal error(error_message: String)

var program: Program
var mod_api: ModAPI

var max_instruction_count: int = 100000

func setup(p: Program, api: ModAPI):
	program = p
	mod_api = api

func run_function(name: String):
	if not program.functions.has(name):
		return
	var local_context: Dictionary = program.globals.duplicate()
	var function: Function = program.functions[name]
	execute_function(function, local_context)

func execute_function(function: Function, local_context: Dictionary):
	var instruction_pointer: int = 0
	var instruction_count: int = 0
	while instruction_pointer < function.instructions.size() and instruction_count < max_instruction_count:
		var instr:Instruction = function.instructions[instruction_pointer]
		instruction_pointer = execute_instruction(function, instr, instruction_pointer, local_context)
		instruction_count += 1

func execute_instruction(function: Function, instr: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	match instr.type:
		Constants.InstructionType.IF: return exec_if(function, instr, instruction_pointer, local_context)
		Constants.InstructionType.ELSE: return function.endif_map[instruction_pointer] + 1
		Constants.InstructionType.END_IF: return instruction_pointer + 1
		Constants.InstructionType.WHILE: return exec_while(function, instr, instruction_pointer, local_context)
		Constants.InstructionType.END_WHILE: return function.end_while_map[instruction_pointer]
		Constants.InstructionType.ASSIGN:
			exec_assign(instr, local_context)
			return instruction_pointer + 1
		Constants.InstructionType.EXPRESSION:
			eval_expression(instr, local_context)
			return instruction_pointer + 1
	return instruction_pointer + 1

func exec_if(function: Function, instr: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	var result = eval_expression(instr, local_context)
	if result:
		return instruction_pointer + 1
	else:
		return function.else_map[instruction_pointer] + 1

func exec_while(function: Function, instr: Instruction, instruction_pointer: int, local_context: Dictionary) -> int:
	var result = eval_expression(instr, local_context)
	if result:
		return instruction_pointer + 1
	else:
		return function.while_end_map[instruction_pointer] + 1

func exec_assign(instr: Instruction, local_context: Dictionary):
	var value = eval_expression(instr, local_context)
	local_context[instr.variable_name] = value
	if program.globals.has(instr.variable_name):
		program.globals[instr.variable_name] = value

func eval_expression(instr: Instruction, local_context: Dictionary):
	var expression = Expression.new()
	var merge_context: Dictionary = mod_api.context.duplicate(true)
	merge_context.merge(local_context, true)
	var err = expression.parse(instr.expression, merge_context.keys())
	if err != OK:
		error.emit("Expression parse error on line %s: %s" % [instr.script_line+1, expression.get_error_text()])
		return null
	var result = expression.execute(merge_context.values(), mod_api)
	if expression.has_execute_failed():
		print(expression.get_error_text())
		return null
	else:
		return result
