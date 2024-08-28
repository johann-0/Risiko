class_name Player_UI
extends Control

func _ready():
	pass

func _process(_delta):
	pass

static func new_player_UI(position: Vector2i, id: int, name: String, color: Color) -> Player_UI:
	var my_scene: PackedScene = load("res://Scenes/player_ui.tscn")
	var toReturn: Player_UI = my_scene.instantiate()
	var text = ""
	if id < 10:
		text += "0"
	text += str(id) + ": " + name
	toReturn.get_child(0).text = text
	toReturn.get_child(1).color = color
	toReturn.position = position
	return toReturn

func setColor(newColor: Color):
	$Color.color = newColor

func setTextColor(newColor: Color):
	$Text.add_theme_color_override("font_color", newColor)
