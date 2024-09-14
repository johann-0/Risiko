extends Node2D

var client: UDP_client = GameData.client
var g_multiplayer = GameData.multiplayer

func _ready() -> void:
	## Connect functions
	GameData.end_turn.connect(on_end_turn)
	client.peer_connected.connect(on_peer_connected)
	client.peer_disconnected.connect(on_peer_disconnected)
	#client.connected_to_server.connect(on_connected_to_server)
	#client.connection_failed.connect(on_connection_failed)
	client.disconnected_from_server.connect(on_disconnected_from_server)
	#for province in GameData.provinces:
		#province.remote_info_updated.connect(on_remote_info_updated)
	
	## Assign provinces randomly to the players
	if GameData.cur_phase == GameData.Phase.deploy:
		var prov_owners: Array = []
		prov_owners.resize(GameData.NUM_PROV)
		prov_owners.fill(-1)
		var cur_player_ind: int = 0
		var i: int = 0
		for prov_owner in prov_owners:
			prov_owners[i] = cur_player_ind
			cur_player_ind += 1
			cur_player_ind = cur_player_ind % GameData.players.size()
			i += 1
		prov_owners.shuffle()
		i = 0
		for province in GameData.provinces:
			province.soldiers = 1
			province.owner = prov_owners[i]
			province.emit_updated()
			i += 1
		#GameData.dep_avail_sols = GameData.calculate_soldiers(GameData.glo_player_ind)
	
	## Update game data and UI
	on_end_turn(-1, 0, true, GameData.Phase.lobby, GameData.cur_phase, true)
	#GameData.new_turn.emit(-1, 0, true, GameData.Phase.lobby, GameData.cur_phase, true)
#
#func on_remote_info_updated(prov_id: int):
	#var prov: Province = GameData.provinces[prov_id]
	#update_info.rpc(prov_id, prov.owner, prov.soldiers, prov.to_add)
#
#@rpc("any_peer", "call_remote")
#func update_info(prov_id: int, _owner: int, _soldiers: int, _to_add: int):
	#var prov: Province = GameData.provinces[prov_id]
	#prov.owner = _owner; prov.soldiers = _soldiers; prov.to_add = _to_add
	#prov.emit_updated()

func on_end_turn(old_idx:int, new_idx:int, idx_chgd:bool \
  , old_phase:GameData.Phase, new_phase:GameData.Phase, phase_changed:bool):
	match new_phase:
		GameData.Phase.init_deploy:
			GameData.dep_avail_sols = 1
		GameData.Phase.deploy:
			GameData.dep_avail_sols = GameData.calculate_soldiers(GameData.glo_player_ind)
		GameData.Phase.attack:
			pass
		GameData.Phase.fortify:
			pass
		_:
			pass
	## Update UI
	GameData.new_turn.emit(old_idx,new_idx,idx_chgd,old_phase,new_phase,phase_changed)

func _unhandled_input(_event) -> void:
	if _event is InputEventKey:
		if GameData.loc_sel_prov != -1:
			if _event.is_action_pressed("down"):
				Commander.add_command(UpOrDownPressed.new([GameData.loc_sel_prov, true]))
			elif _event.is_action_pressed("up"):
				Commander.add_command(UpOrDownPressed.new([GameData.loc_sel_prov, false]))

func on_peer_connected(id: int) -> void:
	if g_multiplayer.is_server():
		client.disconnect_client(id, "Game already started")
func on_peer_disconnected(_id: int) -> void:
	# Save game state and end the game?
	pass
func on_disconnected_from_server() -> void:
	pass
