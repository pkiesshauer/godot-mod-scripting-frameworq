extends TextureRect
class_name GridElement

func assign_shape(shape: GameConstants.shape, color: GameConstants.color):
	match shape:
		GameConstants.shape.TRIANGLE: assign_texture(GameConstants.TRIANGLE_TEX)
		GameConstants.shape.SQUARE: assign_texture(GameConstants.SQUARE_TEX)
		GameConstants.shape.CIRCLE: assign_texture(GameConstants.CIRCLE_TEX)
	self_modulate = GameConstants.colors[color]

func assign_texture(tex: Texture2D):
	texture = tex

func reset():
	assign_texture(GameConstants.SQUARE_TEX)
	self_modulate = GameConstants.colors[GameConstants.color.WHITE]
