class_name ProvinceSelected extends BaseCommand

var prov_id: int
var is_left_click: bool

func _init(arr: Array) -> void:
	prov_id = arr[0]
	is_left_click = arr[1]

func to_array() -> Array:
	return [Commander.Commands.ProvSel, [prov_id, is_left_click]]

func process() -> void:
	if is_left_click:
		## Select the province locally
		var old_prov_id = GameData.loc_sel_prov
		GameData.loc_sel_prov = prov_id
		## Update UI
		GameData.new_loc_sel_prov.emit(old_prov_id, GameData.loc_sel_prov)
		## If it's the player's turn
		if GameData.is_loc_players_turn():
			Commander.remote_add_command.rpc(to_array())
	else:
		if GameData.is_loc_players_turn():
			Commander.remote_add_command.rpc(to_array())

func remote_process() -> void:
	if is_left_click:
		## Select the province globally
		var old_prov_id: int = GameData.glo_sel_prov
		GameData.glo_sel_prov = prov_id
		if old_prov_id != -1:
			GameData.provinces[old_prov_id].commit_add()
			GameData.provinces[old_prov_id].emit_updated()
		
		## Update UI
		GameData.new_glo_sel_prov.emit(old_prov_id, GameData.glo_sel_prov)
		## Deselect mov prov
		if old_prov_id != prov_id and GameData.glo_mov_prov != -1:
			Commander.remote_add_command(ProvinceSelected.new([-1, false]).to_array())
			
	else:
		## Deselect old move province
		var old_mov_id: int = GameData.glo_mov_prov
		if old_mov_id != -1 and old_mov_id != prov_id:
			GameData.provinces[old_mov_id].commit_add()
			GameData.provinces[old_mov_id].emit_updated()
		
		## If it's not deploy/init_deploy phase
		if GameData.cur_phase == GameData.Phase.deploy \
		  or GameData.cur_phase == GameData.Phase.init_deploy:
			return
		
		var sel_prov: Province = GameData.provinces[GameData.glo_sel_prov]
		
		if prov_id != -1:
			var mov_prov: Province = GameData.provinces[prov_id]
			var is_neigh: bool = false
			for neigh_id in sel_prov.neighbors:
				if prov_id == neigh_id:
					is_neigh = true; break
			if mov_prov.owner != sel_prov.owner and is_neigh == true and sel_prov.to_add + sel_prov.soldiers > 1:
				#print("new mov prov: " + str(prov_id))
				GameData.glo_mov_prov = prov_id
				
				if prov_id != old_mov_id or mov_prov.to_add == 0:
					mov_prov.soldiers -= 1
					mov_prov.to_add += 1
					mov_prov.emit_updated()
				
				if sel_prov.soldiers > 1 and (prov_id == old_mov_id or sel_prov.to_add == 0):
					sel_prov.soldiers -= 1
					sel_prov.to_add += 1
					sel_prov.emit_updated()
				GameData.new_glo_mov_prov.emit(old_mov_id, GameData.glo_mov_prov)
				return
		
		#print("new mov prov: -1")
		
		sel_prov.commit_add()
		sel_prov.emit_updated()
		
		GameData.glo_mov_prov = -1
		GameData.new_glo_mov_prov.emit(old_mov_id, GameData.glo_mov_prov)
