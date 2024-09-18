class_name ExecutePressed extends BaseCommand

var dice: Array[int]

func _init(_arr: Array) -> void:
	if not _arr.is_empty():
		dice = _arr[0]

func process() -> void:
	match GameData.cur_phase:
		GameData.Phase.attack:
			if GameData.is_loc_players_turn():
				match GameData.cur_b_phase:
					GameData.B_Phase.no_battle:
						## Calculate results
						dice = [0, 0, 0, 0, 0]
						var att_num: int = min(3, GameData.provinces[GameData.glo_sel_prov].to_add)
						var def_num: int = min(2, GameData.provinces[GameData.glo_mov_prov].to_add)
						for i in range(att_num):
							dice[i] = randi() % 6 + 1
						for i in range(def_num):
							dice[i+3] = randi() % 6 + 1
						
						Commander.remote_add_command.rpc(to_array())
					## In moving phase?
					GameData.B_Phase.after_battle:
						Commander.remote_add_command.rpc(to_array())
		_:
			pass

func remote_process() -> void:
	match GameData.cur_phase:
		GameData.Phase.attack:
			match GameData.cur_b_phase:
				GameData.B_Phase.no_battle:
					if GameData.glo_mov_prov == -1:
						return
					
					GameData.cur_b_phase = GameData.B_Phase.in_battle
					GameData.id_print("Emitting attack")
					
					## Roll for a bit
					GameData.start_dice.emit()
					GameData.disable_ui.emit()
					await GameData.get_tree().create_timer(3.0).timeout
					
					GameData.stop_dice.emit(dice)
					
					## Time to read the result
					await GameData.get_tree().create_timer(3.0).timeout
					
					## Calculate the casualties of the battle
					var result: Array[int] = GameData.calculate_battle(dice)
					var att_prov: Province = GameData.provinces[GameData.glo_sel_prov]
					var def_prov: Province = GameData.provinces[GameData.glo_mov_prov]
					att_prov.to_add -= result[0]
					def_prov.to_add -= result[1]
					## If no troops defending, take over province
					if def_prov.to_add + def_prov.soldiers == 0:
						def_prov.owner = att_prov.owner
						var num_att_sold: int = 0
						for i in range(3):
							if dice[i] != 0:
								num_att_sold += 1
						num_att_sold -= result[0]
						def_prov.soldiers = num_att_sold
						att_prov.to_add -= num_att_sold
						## Make all att_troops deployed
						att_prov.to_add += att_prov.soldiers - 1
						att_prov.soldiers = 1
						
						att_prov.emit_updated()
						def_prov.emit_updated()
						if att_prov.to_add == 0:
							if GameData.is_loc_players_turn():
								GameData.enable_ui.emit()
								Commander.add_command(ProvinceSelected.new([-1, false]))
							GameData.cur_b_phase = GameData.B_Phase.no_battle
						else:
							GameData.cur_b_phase = GameData.B_Phase.after_battle
						return
					## If no more troops in to_add, then move some from soldiers
					elif def_prov.to_add == 0:
						def_prov.to_add += 1
						def_prov.soldiers -= 1
					## If no more attackers left
					elif att_prov.to_add == 0:
						## If attack is not possible anymore
						if att_prov.soldiers == 1:
							## Stop attack (deselect attacking province)
							GameData.cur_b_phase = GameData.B_Phase.no_battle
							if GameData.is_loc_players_turn():
								GameData.enable_ui.emit()
								Commander.add_command(ProvinceSelected.new([-1, false]))
							return
						else:
							att_prov.soldiers -= 1
							att_prov.to_add += 1
					
					att_prov.emit_updated()
					def_prov.emit_updated()
					GameData.cur_b_phase = GameData.B_Phase.no_battle
					if GameData.is_loc_players_turn():
						GameData.enable_ui.emit()
				
				GameData.B_Phase.after_battle:
					if GameData.glo_mov_prov != -1:
						var mov_prov: Province = GameData.provinces[GameData.glo_mov_prov]
						var sel_prov: Province = GameData.provinces[GameData.glo_sel_prov]
						mov_prov.commit_add()
						sel_prov.commit_add()
						mov_prov.emit_updated()
						sel_prov.emit_updated()
					GameData.cur_b_phase = GameData.B_Phase.no_battle
					if GameData.is_loc_players_turn():
						GameData.enable_ui.emit()
		_:
			pass

func to_array() -> Array:
	return [Commander.Commands.Exec, [dice]]
