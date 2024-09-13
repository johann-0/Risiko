class_name Player_UI
extends Control

static func new_player_UI(pPos: Vector2i, pName: String, pColor: Color) -> Player_UI:
	var my_scene: PackedScene = load("res://Scenes/player_ui.tscn")
	var toReturn: Player_UI = my_scene.instantiate()
	toReturn.set_text(pName)
	toReturn.set_color(pColor)
	toReturn.reset_background_color()
	toReturn.position = pPos
	return toReturn

func set_text(text: String) -> void:
	$Text.text = text

func get_text() -> String:
	return $Text.text

func set_color(new_color: Color) -> void:
	if new_color == $Color.color:
		return
	if new_color == Color.AZURE:
		$Color.hide()
		$Random.show()
	else:
		$Random.hide()
		$Color.show()
		$Color.color = new_color

func set_text_color(newColor: Color) -> void:
	$Text.add_theme_color_override("font_color", newColor)

func get_background_color() -> Color:
	return $Background.color

func set_background_color(newColor: Color) -> void:
	$Background.color = newColor

func reset_background_color() -> void:
	set_background_color(Color.SADDLE_BROWN)
