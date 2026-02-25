extends ModAPI
class_name ExampleModAPI

signal display(text: String)

#functions need an explicit return type for the Expression class to work.
func send_display_signal(text) -> void:
	display.emit(str(text))

func hurt_player(dmg) -> void:
	if context.has("player_health"):
		if context["player_health"] is int:
			context["player_health"] -= dmg
