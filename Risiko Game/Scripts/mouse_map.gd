extends Sprite2D

func _unhandled_input(event):
	if event is InputEventMouseButton:
		var mouseX = get_global_mouse_position().x - global_position.x
		var mouseY = get_global_mouse_position().y - global_position.y
		
		if event.button_index != MOUSE_BUTTON_LEFT \
			or event.pressed == false \
			or mouseX >= texture.get_width() or mouseX < 0 \
			or mouseY >= texture.get_height() or mouseY < 0:
			return
		
		var color = texture.get_image().get_pixel(mouseX, mouseY)
		var id = color.r8 - 100
		if id < 0 or id >= GameData.NUM_PROV or color.g != 0 or color.b != 0:
			GameData.selectedProvID = -1
		else:
			#print("{ id: " + str(id) + ", " + str(GameData.provinces[id]._name) + " }\n")
			GameData.selectedProvID = id


