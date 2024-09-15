class_name ExecutePressed extends BaseCommand

func _init(_arr: Array) -> void:
	pass

func process() -> void:
	match GameData.cur_phase:
		GameData.Phase.attack:
			if GameData.is_loc_players_turn():
				Commander.remote_add_command(to_array())
		_:
			pass

func remote_process() -> void:
	match GameData.cur_phase:
		GameData.Phase.attack:
			if GameData.glo_mov_prov != -1 and GameData.glo_sel_prov != GameData.glo_mov_prov:
				pass # commence attack!
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.Exec, []]
