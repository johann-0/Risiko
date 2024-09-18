class_name EndTurnPressed extends BaseCommand

func _init(_arr: Array) -> void:
	pass

func process() -> void:
	#var cur_prov = GameData.provinces[prov_id]
	match GameData.cur_phase:
		GameData.Phase.init_deploy, GameData.Phase.deploy:
			if not GameData.is_loc_players_turn():
				return
			Commander.remote_add_command.rpc(to_array())
		GameData.Phase.attack:
			if not GameData.is_loc_players_turn():
				return
			Commander.remote_add_command.rpc(to_array())
		GameData.Phase.fortify:
			if not GameData.is_loc_players_turn():
				return
			Commander.remote_add_command.rpc(to_array())
		_:
			pass

func remote_process() -> void:
	var cur_player: int = GameData.glo_player_ind
	var next_player: int = (cur_player + 1) % GameData.players.size()
	GameData.enable_ui.emit()
	match GameData.cur_phase:
		GameData.Phase.init_deploy:
			if GameData.dep_avail_sols != 0:
				return
			GameData.glo_player_ind = next_player
			var no_wastelands = true
			for province in GameData.provinces:
				if province.owner == -1:
					no_wastelands = false; break
			## Move onto deploy phase
			if no_wastelands == true: 
				GameData.cur_phase = GameData.Phase.deploy
				GameData.end_turn.emit(cur_player, next_player \
				  , GameData.Phase.init_deploy, GameData.Phase.deploy)
			## Stay with with init_deploy
			else: 
				GameData.end_turn.emit(cur_player, next_player \
				  , GameData.Phase.init_deploy, GameData.Phase.init_deploy)
		GameData.Phase.deploy:
			if GameData.dep_avail_sols != 0:
				return
			GameData.cur_phase = GameData.Phase.attack
			GameData.end_turn.emit(cur_player, cur_player, GameData.Phase.deploy, GameData.Phase.attack)
		GameData.Phase.attack:
			if GameData.cur_b_phase != GameData.B_Phase.no_battle:
				return
			GameData.cur_phase = GameData.Phase.fortify
			GameData.fort_already_moved = false
			GameData.end_turn.emit(cur_player, cur_player, GameData.Phase.attack, GameData.Phase.fortify)
		GameData.Phase.fortify:
			GameData.cur_phase = GameData.Phase.deploy
			GameData.glo_player_ind = next_player
			GameData.end_turn.emit(cur_player, next_player, GameData.Phase.fortify, GameData.Phase.deploy)
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.EndTurn, []]
