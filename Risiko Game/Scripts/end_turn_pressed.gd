class_name EndTurnPressed extends BaseCommand

func _init(_arr: Array) -> void:
	pass

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
	var cur_player: int = GameData.glo_player_ind
	var next_player: int = (cur_player + 1) % GameData.players.size()
	match GameData.cur_phase:
		GameData.Phase.init_deploy:
			if GameData.dep_avail_sols == 0:
				var no_wastelands = true
				for province in GameData.provinces:
					if province.owner == -1:
						no_wastelands = false; break
				GameData.glo_player_ind = next_player
				if no_wastelands == true: # move onto deploy phase
					GameData.cur_phase = GameData.Phase.deploy
					GameData.end_turn.emit(cur_player, next_player \
					  , GameData.Phase.init_deploy, GameData.Phase.deploy)
				else: # continue with init_deploy
					GameData.end_turn.emit(cur_player, next_player \
					  , GameData.Phase.init_deploy, GameData.Phase.init_deploy)
		GameData.Phase.deploy:
			if GameData.dep_avail_sols == 0:
				GameData.cur_phase = GameData.Phase.attack
				GameData.end_turn.emit(cur_player, cur_player \
				  , GameData.Phase.deploy, GameData.Phase.attack)
		GameData.Phase.attack:
			pass
		GameData.Phase.fortify:
			pass
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.EndTurn, []]
