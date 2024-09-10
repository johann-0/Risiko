extends TextureRect

func _gui_input(event):
	var mouse_pos = get_local_mouse_position()
	var image = texture.get_image()
	if mouse_pos.y < 0 or mouse_pos.y >= image.get_height():
		return
	elif mouse_pos.y < 0 or mouse_pos.x >= image.get_width():
		return
	elif texture.get_image().get_pixel(mouse_pos.x, mouse_pos.y).a != 0:
		# Handle the input
		accept_event()
