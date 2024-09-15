extends Sprite2D

func _unhandled_input(event):
	if GameData.in_a_battle == true:
		return
	
	if event is InputEventMouseButton:
		var mouseX = get_global_mouse_position().x - global_position.x
		var mouseY = get_global_mouse_position().y - global_position.y
		if event.pressed == false \
			or mouseX >= texture.get_width() or mouseX < 0 \
			or mouseY >= texture.get_height() or mouseY < 0:
			return
		
		var color: Color = texture.get_image().get_pixel(mouseX, mouseY)
		var id: int = color.r8 - 100
		if id < 0 or id >= GameData.NUM_PROV or color.g != 0 or color.b != 0:
			id = -1
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			Commander.add_command(ProvinceSelected.new([id, true]))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Commander.add_command(ProvinceSelected.new([id, false]))
		
		
			#if GameData.glo_mov_prov != -1:
				#GameData.glo_mov_prov = -1
			#if id < 0 or id >= GameData.NUM_PROV or color.g != 0 or color.b != 0:
				#GameData.loc_sel_prov = -1
			#else:
				#print("{ id: " + str(id) + ", " + str(GameData.provinces[id].name) + " }\n")
				#GameData.loc_sel_prov = id
		#
		#elif event.button_index == MOUSE_BUTTON_RIGHT \
		  #and GameData.glo_player_ind == GameData.loc_player_ind:
			#if GameData.cur_phase == GameData.Phase.attack:
				#if id >= 0 and id < GameData.NUM_PROV and color.g == 0 and color.b == 0 \
				  #and GameData.provinces[id].owner != GameData.loc_player_ind \
				  #and GameData.provinces[GameData.loc_sel_prov].owner == GameData.loc_player_ind \
				  #and GameData.provinces[GameData.loc_sel_prov].soldiers > 1:
					#var isNeighboringProvince = false
					#for neighbor_index in GameData.provinces[GameData.loc_sel_prov].neighbors:
						#if neighbor_index == id:
							#isNeighboringProvince = true
					#if isNeighboringProvince:
						#GameData.glo_mov_prov = id
					#else:
						#GameData.glo_mov_prov = -1
				#else:
					#GameData.glo_mov_prov = -1
			#
			#elif GameData.cur_phase == GameData.Phase.fortify \
			  #and GameData.already_moved == false:
				#if id >= 0 and id < GameData.NUM_PROV and color.g == 0 and color.b == 0 \
				  #and GameData.loc_player_ind == GameData.provinces[id].owner \
				  #and GameData.loc_player_ind == GameData.provinces[GameData.selectedProvID].owner \
				  #and GameData.provinces[GameData.selectedProvID].soldiers > 1 \
				  #and GameData.are_provs_neighbors(GameData.selectedProvID, id):
					#print("new move prov_id: " + str(id))
					#GameData.glo_mov_prov = id
				#else:
					#GameData.glo_mov_prov = -1
