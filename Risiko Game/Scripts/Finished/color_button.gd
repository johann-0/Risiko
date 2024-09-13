class_name Color_Button
extends Control

signal button_pressed(color: Color)

static func new_color_button(newPos: Vector2i, new_col: Color) -> Color_Button:
	var my_scene: PackedScene = load("res://Scenes/color_button.tscn")
	var toReturn: Color_Button = my_scene.instantiate()
	toReturn.position = newPos
	toReturn.set_color(new_col)
	return toReturn

func _on_pressed() -> void:
	button_pressed.emit(get_color())

func set_color(new_col: Color) -> void:
	if new_col == Color.AZURE: # in this case it's the random icon
		var image: Image = Image.new()
		var err = image.load("res://Assets/ui/random_icon.png")
		if err != OK:
			print("Error loading random_icon.png: " + str(err))
		$Button.texture_normal = ImageTexture.create_from_image(image)
	else:
		$Button.texture_normal = GradientTexture2D.new()
		$Button.texture_normal.gradient = Gradient.new()
		$Button.texture_normal.gradient.remove_point(1)
		$Button.texture_normal.height = 24
		$Button.texture_normal.width = 24
		$Button.texture_normal.gradient.set_color(0, new_col)

func get_color() -> Color:
	if $Button.texture_normal is GradientTexture2D:
		return $Button.texture_normal.gradient.get_color(0)
	else:
		return Color.AZURE

func is_covered() -> bool:
	return $Cover.visible

func set_covered(shouldBeCovered: bool) -> void:
	if shouldBeCovered:
		$Cover.show()
	else:
		$Cover.hide()
