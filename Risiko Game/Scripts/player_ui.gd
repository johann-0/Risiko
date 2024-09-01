class_name Player_UI
extends Control

func _ready():
	pass

func _process(_delta):
	pass

static func new_player_UI(pPos: Vector2i, pId: int, pName: String, pColor: Color) -> Player_UI:
	var my_scene: PackedScene = load("res://Scenes/player_ui.tscn")
	var toReturn: Player_UI = my_scene.instantiate()
	var text = ""
	if pId < 10:
		text += "0"
	text += str(pId) + ": " + pName
	toReturn.setText(text)
	toReturn.setColor(pColor)
	toReturn.position = pPos
	return toReturn

func setText(text: String):
	$Text.text = text

func getText():
	return $Text.text

func setColor(newColor: Color):
	$Color.color = newColor

func setTextColor(newColor: Color):
	$Text.add_theme_color_override("font_color", newColor)

func getBackgroundColor():
	return $Background.color

func setBackgroundColor(newColor: Color):
	$Background.color = newColor

func resetBackgroundColor():
	setBackgroundColor(Color.SADDLE_BROWN)
