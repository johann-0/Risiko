class_name UpOrDownPressed extends BaseCommand

var is_up_pressed: bool
var prov_id: int

func _init(_arr: Array) -> void:
	prov_id = _arr[0]
	is_up_pressed = _arr[1]

func process() -> void:
	#var cur_prov = GameData.provinces[prov_id]
	match GameData.cur_phase:
		GameData.Phase.init_deploy, GameData.Phase.deploy:
			if GameData.is_loc_players_turn():
				Commander.remote_add_command.rpc(to_array())
		GameData.Phase.attack:
			if GameData.is_loc_players_turn():
				Commander.remote_add_command.rpc(to_array())
			elif GameData.glo_mov_prov != -1 and GameData.provinces[GameData.glo_mov_prov].owner == GameData.loc_player_ind:
				Commander.remote_add_command.rpc(ProvinceSelected.new([GameData.glo_mov_prov, is_up_pressed]).to_array())
		GameData.Phase.fortify:
			pass
		_:
			pass

func remote_process() -> void:
	var cur_prov = GameData.provinces[prov_id]
	match GameData.cur_phase:
		GameData.Phase.init_deploy:
			if is_up_pressed:
				if GameData.dep_avail_sols > 0 and cur_prov.owner == -1:
					cur_prov.to_add += 1
					cur_prov.owner = GameData.glo_player_ind
					GameData.dep_avail_sols -= 1
					cur_prov.emit_updated()
			else:
				if cur_prov.to_add > 0 and cur_prov.owner == GameData.glo_player_ind:
					cur_prov.to_add -= 1
					cur_prov.check_if_empty()
					GameData.dep_avail_sols += 1
					cur_prov.emit_updated()
		
		GameData.Phase.deploy:
			if cur_prov.owner != GameData.glo_player_ind:
				return
			if is_up_pressed:
				if GameData.dep_avail_sols > 0:
					cur_prov.to_add += 1
					cur_prov.owner = GameData.glo_player_ind
					GameData.dep_avail_sols -= 1
					cur_prov.emit_updated()
			else:
				if cur_prov.to_add > 0:
					cur_prov.to_add -= 1
					cur_prov.check_if_empty()
					GameData.dep_avail_sols += 1
					cur_prov.emit_updated()
		
		GameData.Phase.attack:
			if GameData.glo_mov_prov == -1 or GameData.provinces[GameData.glo_sel_prov].owner != GameData.glo_player_ind:
				return
			## If attacking
			if prov_id == GameData.glo_sel_prov:
				if is_up_pressed and cur_prov.soldiers > 1:
					cur_prov.soldiers -= 1
					cur_prov.to_add += 1
					cur_prov.emit_updated()
				elif not is_up_pressed and cur_prov.to_add > 1:
					cur_prov.soldiers += 1
					cur_prov.to_add -= 1
					cur_prov.emit_updated()
			## If being attacked TODO: test this out
			elif prov_id == GameData.glo_mov_prov and GameData.glo_mov_prov != -1 \
			  and GameData.provinces[GameData.glo_mov_prov].owner == GameData.loc_player_ind:
				var attacked_prov: Province = GameData.provinces[GameData.glo_mov_prov]
				if is_up_pressed and attacked_prov.soldiers > 0:
					cur_prov.soldiers -= 1
					cur_prov.to_add += 1
					cur_prov.emit_updated()
				elif not is_up_pressed and cur_prov.to_add > 1:
					cur_prov.soldiers += 1
					cur_prov.to_add -= 1
					cur_prov.emit_updated()
		GameData.Phase.fortify:
			pass
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.UpDown, [prov_id, is_up_pressed]]
