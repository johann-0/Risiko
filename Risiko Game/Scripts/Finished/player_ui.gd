class_name Player_UI
extends Control

static func new_player_UI(pPos: Vector2i, pName: String, pColor: Color) -> Player_UI:
	var my_scene: PackedScene = load("res://Scenes/player_ui.tscn")
	var toReturn: Player_UI = my_scene.instantiate()
	toReturn.setText(pName)
	toReturn.setColor(pColor)
	toReturn.position = pPos
	return toReturn

func setText(text: String) -> void:
	$Text.text = text

func getText() -> String:
	return $Text.text

func setColor(newColor: Color) -> void:
	$Color.color = newColor

func setTextColor(newColor: Color) -> void:
	$Text.add_theme_color_override("font_color", newColor)

func getBackgroundColor() -> Color:
	return $Background.color

func setBackgroundColor(newColor: Color) -> void:
	$Background.color = newColor

func resetBackgroundColor() -> void:
	setBackgroundColor(Color.SADDLE_BROWN)
