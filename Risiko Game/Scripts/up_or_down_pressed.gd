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
			pass
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
			if is_up_pressed:
				if GameData.dep_avail_sols > 0 and cur_prov.owner == GameData.glo_player_ind:
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
		GameData.Phase.attack:
			pass
		GameData.Phase.fortify:
			pass
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.UpDown, [prov_id, is_up_pressed]]
