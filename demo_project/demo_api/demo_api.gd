extends ModAPI
class_name DemoAPI

var game: Game

func assign_shape(shape, color, x, y) -> void:
	if shape is int:
		if shape < 0 or shape > GameConstants.shape.size():
			return
	if color is int:
		if color < 0 or color > GameConstants.color.size():
			return
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return
	game.assign_shape(shape, color, int(x), int(y))

func assign_random_shape(color, x, y) -> void:
	if color is int:
		if color < 0 or color > GameConstants.color.size():
			return
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return
	game.assign_shape(randi_range(0, GameConstants.shape.size()-1), color, int(x), int(y))

func assign_random_color(shape, x, y) -> void:
	if shape is int:
		if shape < 0 or shape > GameConstants.shape.size():
			return
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return
	game.assign_shape(shape, randi_range(0, GameConstants.color.size()-1), int(x), int(y))

func assign_random(x, y) -> void:
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return
	game.assign_shape(randi_range(0, GameConstants.shape.size()-1), randi_range(0, GameConstants.color.size()-1), int(x), int(y))

func shape(x, y) -> int:
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return GameConstants.shape.SQUARE
	return game.get_shape(int(x),int(y))

func color(x, y) -> int:
	if not (str(x).is_valid_int() and str(x).is_valid_int()): return GameConstants.color.WHITE
	return game.get_color(int(x),int(y))


func reset() -> void:
	game.reset()
