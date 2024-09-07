extends Sprite2D

func _unhandled_input(event):
	if GameData.diceAreRolling == true:
		return
	if event is InputEventMouseButton:
		var mouseX = get_global_mouse_position().x - global_position.x
		var mouseY = get_global_mouse_position().y - global_position.y
		
		if event.pressed == false \
			or mouseX >= texture.get_width() or mouseX < 0 \
			or mouseY >= texture.get_height() or mouseY < 0:
			return
		
		var color = texture.get_image().get_pixel(mouseX, mouseY)
		var id = color.r8 - 100
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if GameData.gameAttackedProvID != -1:
				GameData.gameAttackedProvID = -1
			if id < 0 or id >= GameData.NUM_PROV or color.g != 0 or color.b != 0:
				GameData.selectedProvID = -1
			else:
				#print("{ id: " + str(id) + ", " + str(GameData.provinces[id]._name) + " }\n")
				GameData.selectedProvID = id
		
		elif event.button_index == MOUSE_BUTTON_RIGHT \
		  and GameData.localPlayerIndex == GameData.turnPlayerIndex:
			if GameData.gamePhase == GameData.Phase.attack:
				#print("1") # DEBUG
				if id >= 0 and id < GameData.NUM_PROV and color.g == 0 and color.b == 0 \
				  and GameData.provinces[id]._owner != GameData.localPlayerIndex \
				  and GameData.provinces[GameData.selectedProvID]._owner == GameData.localPlayerIndex \
				  and GameData.provinces[GameData.selectedProvID]._soldiers > 1:
					#print("2") # DEBUG
					var isNeighboringProvince = false
					for neighbor_index in GameData.provinces[GameData.selectedProvID]._neighbors:
						if neighbor_index == id:
							isNeighboringProvince = true
					if isNeighboringProvince:
						print("new attack provid: " + str(id))
						GameData.gameAttackedProvID = id
					else:
						GameData.gameAttackedProvID = -1
				else:
					GameData.gameAttackedProvID = -1
			
			elif GameData.gamePhase == GameData.Phase.fortify \
			  and GameData.already_moved == false:
				#print("WORKS 1") # DEBUG
				if id >= 0 and id < GameData.NUM_PROV and color.g == 0 and color.b == 0 \
				  and GameData.localPlayerIndex == GameData.provinces[id]._owner \
				  and GameData.localPlayerIndex == GameData.provinces[GameData.selectedProvID]._owner \
				  and GameData.provinces[GameData.selectedProvID]._soldiers > 1:
					#print("WORKS 2") # DEBUG
					if GameData.are_provs_reachable(GameData.selectedProvID, id):
						print("new move provid: " + str(id))
						GameData.gameAttackedProvID = id
					else:
						GameData.gameAttackedProvID = -1
				else:
					GameData.gameAttackedProvID = -1


