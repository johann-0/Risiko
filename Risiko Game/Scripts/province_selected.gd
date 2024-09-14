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
		# Select the province locally
		var old_prov_id = GameData.loc_sel_prov
		GameData.loc_sel_prov = prov_id
		if GameData.is_loc_players_turn():
			Commander.remote_add_command.rpc(to_array())
		# Update UI
		GameData.new_loc_sel_prov.emit(old_prov_id, GameData.loc_sel_prov)
	else:
		pass

func remote_process() -> void:
	if is_left_click:
		# Select the province globally
		var old_prov_id = GameData.glo_sel_prov
		GameData.glo_sel_prov = prov_id
		# Update UI
		GameData.new_glo_sel_prov.emit(old_prov_id, GameData.glo_sel_prov)
		
		# Deselect globally moved province
		if GameData.glo_mov_prov != -1:
			var old_mov_id: int = GameData.glo_mov_prov
			GameData.glo_mov_prov = -1
			# Update UI
			GameData.new_glo_mov_prov.emit(old_mov_id, GameData.glo_mov_prov)
		
	else:
		pass
