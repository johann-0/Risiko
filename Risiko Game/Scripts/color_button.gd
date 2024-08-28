class_name Color_Button
extends Control

signal button_pressed(color: Color)

static func new_color_button(newPos: Vector2i, newCol: Color):
	var my_scene: PackedScene = load("res://Scenes/color_button.tscn")
	var toReturn: Color_Button = my_scene.instantiate()
	toReturn.position = newPos
	var button = toReturn.get_child(0)
	button.texture_normal = GradientTexture2D.new()
	button.texture_normal.gradient = Gradient.new()
	button.texture_normal.gradient.remove_point(1)
	button.texture_normal.height = 24
	button.texture_normal.width = 24
	toReturn.setColor(newCol)
	return toReturn

func _on_pressed():
	button_pressed.emit(getColor())

func setColor(newCol: Color):
	$Button.texture_normal.gradient.set_color(0, newCol)

func getColor():
	return $Button.texture_normal.gradient.get_color(0)

func isCovered():
	return $Cover.visible

func setCovered(shouldBeCovered: bool):
	if shouldBeCovered:
		$Cover.show()
	else:
		$Cover.hide()
