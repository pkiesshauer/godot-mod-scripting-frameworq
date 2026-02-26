extends MarginContainer
class_name DemoProject

@export var code_edit: CodeEdit
@export var v_box_container_constants: VBoxContainer

@export var button_compile: Button
@export var option_button_functions: OptionButton
@export var button_run: Button

@export var game: Game
@export var output: RichTextLabel

var api: DemoAPI
var program: Program
func _ready() -> void:
	api = DemoAPI.new()
	api.context.merge(GameConstants.game_globals)
	api.game = game
	setup()

func setup():
	setup_code_edit()
	setup_constant_buttons()

func compile_script():
	var compiler: Compiler = Compiler.new()
	program = compiler.compile(code_edit.text)
	if program.error == OK:
		compile_success()
		print(program)
	else:
		compile_error()

func fill_function_options():
	option_button_functions.clear()
	if program == null: return
	for f in program.functions.keys():
		option_button_functions.add_item(f)
	if program.functions.size() > 0:
		option_button_functions.select(0)
		button_run.disabled = false
	else:
		button_run.disabled = true

func compile_error():
	add_output_text(program.error_message, "orange")

func compile_success():
	fill_function_options()
	add_output_text("Compiled Successfully.", "green")

func run_function() -> void:
	if program == null: return
	var interpreter: Interpreter = Interpreter.new()
	interpreter.setup(program, api)
	interpreter.error.connect(on_interpreter_error)
	var function_name: String = program.functions.keys()[option_button_functions.selected]
	interpreter.run_function(function_name)
	return

func setup_code_edit():
	var sh = code_edit.syntax_highlighter
	if sh is CodeHighlighter:
		for kw in GameConstants.game_globals.keys():
			sh.add_keyword_color(kw, Color.CHARTREUSE)

func setup_constant_buttons():
	for shape in GameConstants.shape.size():
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2i(64, 64)
		b.icon = GameConstants.shapes[shape]
		b.pressed.connect(on_button_constant_pressed.bind(shape))
		v_box_container_constants.add_child(b)
	for color in GameConstants.color.size():
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2i(64, 64)
		b.icon = GameConstants.SQUARE_FULL_TEX
		b.self_modulate = GameConstants.colors[color]
		b.pressed.connect(on_button_constant_pressed.bind(color + GameConstants.shape.size()))
		v_box_container_constants.add_child(b)

func add_output_text(text: String, color: String):
	text = "[color=%s]>> %s[/color]\n" % [color, text]
	output.append_text(text)

func on_button_constant_pressed(constant: int):
	code_edit.insert_text_at_caret(GameConstants.game_globals.keys()[constant])
	code_edit.grab_focus()

func on_interpreter_error(error_message: String):
	add_output_text(error_message, "red")

func _on_button_compile_pressed() -> void:
	compile_script()

func _on_button_run_pressed() -> void:
	run_function()
