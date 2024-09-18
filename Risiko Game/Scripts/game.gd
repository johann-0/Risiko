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
	
	## Assign provinces randomly to the players
	if GameData.cur_phase == GameData.Phase.deploy:
		if g_multiplayer.is_server():
			distribute_provinces()
			GameData.dep_avail_sols = GameData.calculate_soldiers(GameData.glo_player_ind)
			on_end_turn(-1, 0, GameData.Phase.lobby, GameData.cur_phase)
	else:
		## Update game data and UI
		on_end_turn(-1, 0, GameData.Phase.lobby, GameData.cur_phase)

func distribute_provinces() -> void:
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
	## Send GameData.players to eberyone
	var to_send: Array = []
	for prov in GameData.provinces:
		to_send.append(prov._to_send_json())
	receive_distributed_provinces.rpc(to_send)

@rpc("authority", "call_remote")
func receive_distributed_provinces(prov_arr: Array):
	var i: int = 0
	for province in GameData.provinces:
		province._from_sent_json(prov_arr[i])
		province.emit_updated()
		i += 1
	on_end_turn(-1, 0, GameData.Phase.lobby, GameData.cur_phase)

func on_end_turn(old_idx:int, new_idx:int \
  , old_phase:GameData.Phase, new_phase:GameData.Phase):
	match old_phase:
		GameData.Phase.init_deploy, GameData.Phase.deploy:
			for prov in GameData.provinces:
				if prov.to_add > 0:
					prov.soldiers += prov.to_add
					prov.to_add = 0
					prov.emit_updated()
		GameData.Phase.attack:
			pass
		GameData.Phase.fortify:
			pass
		_:
			pass
	
	match new_phase:
		GameData.Phase.init_deploy:
			id_print("Phase: INIT_DEPLOYYY")
			GameData.dep_avail_sols = 1
		GameData.Phase.deploy:
			id_print("Phase: DEPLOYYY")
			GameData.dep_avail_sols = GameData.calculate_soldiers(GameData.glo_player_ind)
		GameData.Phase.attack:
			id_print("Phase: ATAKK")
		GameData.Phase.fortify:
			id_print("Phase: PORTIFY")
		_:
			pass
	## Update UI
	GameData.new_turn.emit(old_idx,new_idx,old_phase,new_phase)

func _unhandled_input(_event) -> void:
	if _event is InputEventKey:
		if GameData.loc_sel_prov != -1:
			if _event.is_action_pressed("down"):
				Commander.add_command(UpOrDownPressed.new([GameData.loc_sel_prov, false]))
			elif _event.is_action_pressed("up"):
				Commander.add_command(UpOrDownPressed.new([GameData.loc_sel_prov, true]))
		if _event.is_action_pressed("endTurn") and $Control/Screen/EndTurn.disabled == false \
		  and GameData.is_loc_players_turn():
			Commander.add_command(EndTurnPressed.new([]))
		elif _event.is_action_pressed("execute"):
			var att_num: int = GameData.provinces[GameData.glo_sel_prov].to_add
			var def_num: int = GameData.provinces[GameData.glo_mov_prov].to_add
			Commander.add_command(ExecutePressed.new([]))

func on_peer_connected(id: int) -> void:
	if g_multiplayer.is_server():
		client.disconnect_client(id, "Game already started")
func on_peer_disconnected(_id: int) -> void:
	# Save game state and end the game?
	pass
func on_disconnected_from_server() -> void:
	pass

func id_print(text: String)->void:
	GameData.id_print(text)
