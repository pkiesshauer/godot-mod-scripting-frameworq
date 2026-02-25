extends RefCounted
class_name GameConstants

const CIRCLE_TEX: Texture2D = preload("uid://bnn6saik26qjf")
const SQUARE_TEX: Texture2D = preload("uid://ctrf6avvh04r8")
const TRIANGLE_TEX: Texture2D = preload("uid://bcld3omanav8x")
const SQUARE_FULL_TEX: Texture2D = preload("uid://ddv4ti2ecb1m6")

enum shape {TRIANGLE, SQUARE, CIRCLE}
enum color {WHITE, BLACK, RED, GREEN, BLUE, YELLOW}

const colors: Dictionary[color, Color] = {
	color.WHITE: Color.WHITE,
	color.BLACK: Color.BLACK,
	color.RED: Color.RED,
	color.GREEN: Color.GREEN,
	color.BLUE: Color.BLUE,
	color.YELLOW: Color.YELLOW
}

const shapes: Dictionary[shape, Texture2D] = {
	shape.TRIANGLE: TRIANGLE_TEX,
	shape.SQUARE: SQUARE_TEX,
	shape.CIRCLE: CIRCLE_TEX
}

const game_globals: Dictionary[String, Variant] = {
	"SHAPE_TRIANGLE": shape.TRIANGLE,
	"SHAPE_SQUARE": shape.SQUARE,
	"SHAPE_CIRCLE": shape.CIRCLE,
	"COLOR_WHITE": color.WHITE,
	"COLOR_BLACK": color.BLACK,
	"COLOR_RED": color.RED,
	"COLOR_GREEN": color.GREEN,
	"COLOR_BLUE": color.BLUE,
	"COLOR_YELLOW": color.YELLOW
}
