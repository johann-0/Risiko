extends TextureRect

func _gui_input(_event):
	if _event is InputEventMouseButton or _event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		var image = texture.get_image()
		if mouse_pos.y >= 0 and mouse_pos.y < image.get_height() \
		  and mouse_pos.y >= 0 and mouse_pos.x < image.get_width() \
		  and image.get_pixel(mouse_pos.x, mouse_pos.y).a != 0:
			accept_event() # Block the mouse input
		
		if $AvailTroopsTexture.visible == true:
			mouse_pos = $AvailTroopsTexture.get_local_mouse_position()
			image = $AvailTroopsTexture.texture.get_image()
			if mouse_pos.y >= 0 and mouse_pos.y < image.get_height() \
			  and mouse_pos.x >= 0 and mouse_pos.x < image.get_width() \
			  and image.get_pixel(mouse_pos.x, mouse_pos.y).a != 0:
				accept_event() # Block the mouse input
