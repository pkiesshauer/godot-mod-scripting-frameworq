extends Node

const example1: String = "res://addons/mod_scripting_framework/example/example_script1.txt"
const example2: String = "res://addons/mod_scripting_framework/example/example_script2.txt"

var program1: Program

var api: ExampleModAPI

func _ready() -> void:
	var compiler: Compiler = Compiler.new()
	program1 = compiler.compile(read_file(example1))
	api = ExampleModAPI.new()
	api.context["player_health"] = 99
	api.display.connect(on_api_display)

func run_test_1() -> void:
	run_program(program1, "example1")

func run_test_2() -> void:
	var compiler: Compiler = Compiler.new()
	var program2: Program = compiler.compile(read_file(example2))
	run_program(program2, "print_player_health")
	run_program(program2, "hurt_player")
	run_program(program2, "print_player_health")

func run_program(program: Program, function_name: String):
	var interpreter: Interpreter = Interpreter.new()
	interpreter.setup(program, api)
	var err = interpreter.run_function(function_name)
	if err != OK:
		print()

func read_file(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f != null:
		return f.get_as_text()
	return ""

func on_api_display(text: String):
	print(text)
