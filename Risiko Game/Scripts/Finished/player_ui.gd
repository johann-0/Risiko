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

## TEXT
func set_text(text: String) -> void:
	$Text.text = text
func get_text() -> String:
	return $Text.text

## COLOR ICON
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

## TEXT COLOR
func set_text_color(newColor: Color) -> void:
	$Text.add_theme_color_override("font_color", newColor)
func reset_text_color() -> void:
	set_text_color(Color.WHITE)

## PLAYER TURN STUFF
func is_players_turn():
	set_background_color(Color.WHITE)
	set_text_color(Color.BLACK)
func is_not_player_turn():
	reset_background_color()
	reset_text_color()

## BACKGROUND COLOR
func get_background_color() -> Color:
	return $Background.color
func set_background_color(newColor: Color) -> void:
	$Background.color = newColor
func reset_background_color() -> void:
	set_background_color(Color("ae9b88"))
