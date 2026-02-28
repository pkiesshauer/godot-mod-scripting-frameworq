extends GridContainer
class_name Game

var shapes: Dictionary[int, int]
var colors: Dictionary[int, int]


func assign_shape_color(shape: GameConstants.shape, color: GameConstants.color, x: int, y: int):
	assign_shape(shape, x, y)
	assign_color(color, x, y)

func assign_color(color: GameConstants.color, x: int, y: int):
	var child_nr: int = y * columns + x
	if child_nr <= get_child_count():
		var child: GridElement = get_child(child_nr)
		child.assign_color(color)
		colors[child_nr] = color

func assign_shape(shape: GameConstants.shape, x: int, y: int):
	var child_nr: int = y * columns + x
	if child_nr <= get_child_count():
		var child: GridElement = get_child(child_nr)
		child.assign_shape(shape)
		shapes[child_nr] = shape


func get_shape(x: int, y: int):
	var child_nr: int = y * columns + x
	if shapes.get(child_nr) != null:
		return shapes[child_nr]
	else:
		return GameConstants.shape.SQUARE

func get_color(x: int, y: int):
	var child_nr: int = y * columns + x
	if colors.get(child_nr) != null:
		return colors[child_nr]
	else:
		return GameConstants.color.WHITE


func reset():
	for c in get_children():
		if c is GridElement:
			c.reset()
