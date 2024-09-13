extends Control

const RECONNECT_TIMEOUT: float = 3.0

var client: UDP_client = GameData.client
var g_multiplayer = GameData.multiplayer
var random_deployment: bool = false

func _ready() -> void:
	$Back.pressed.connect(on_back_button_pressed)
	$Start.pressed.connect(on_start_button_pressed)
	$RandomDeployment.toggled.connect(on_random_deployment_toggled)
	var i: int = 0
	for child in $ColorSelection.get_children():
		if child is Color_Button:
			if i < 4:
				child.set_color(GameData.COLORS[i])
			else:
				child.set_color(Color.AZURE)
			child.button_pressed.connect(on_color_button_pressed)
			i += 1
	if not GameData.multiplayer.is_server():
		$RandomDeployment.disabled = true
		$Start.disabled = true
	
	$GameInfo/Name/PlayerName.text = GameData.players[0].name
	$GameInfo/Server/ServerName.text = GameData.server_addr
	#OS.shell_open("https://icanhazip.com/") # DEBUG this is to get the routers ip address
	on_connected_to_server()
	
	#client.peer_connected.connect(on_peer_connected)
	client.peer_disconnected.connect(on_peer_disconnected)
	#client.connected_to_server.connect()
	client.disconnected_from_server.connect(on_disconnected_from_server)
	
	# Send message to host that player has joined the server
	if not GameData.multiplayer.is_server():
		joined_lobby.rpc_id(1, GameData.players[0].name, g_multiplayer.get_unique_id())
	else:
		update_players_ui()

@rpc("any_peer", "call_remote")
func joined_lobby(player_name: String, player_id: int) -> void:
	if GameData.multiplayer.is_server():
		for player in GameData.players:
			if player.name == player_name:
				client.disconnect_client(player_id, "Name is taken")
				return
		GameData.players.append(Player.new(player_id, player_name, Color.AZURE))
		# Send lobby data to everyone
		var i: int = 1
		for peer_id in GameData.multiplayer.get_peers():
			send_lobby_data.rpc_id(peer_id, GameData.gplayers_to_JSON(), i, random_deployment)
			++i
		# Update UI
		update_ui()

func update_ui() -> void:
	update_players_ui(); update_colors_ui()

func update_players_ui() -> void:
	for child in $GameInfo/Players.get_children():
		child.queue_free()
	var i: int = 0
	for player in GameData.players:
		var new_ui: Player_UI = Player_UI.new_player_UI(Vector2i(0,20*i), player.name, player.color)
		$GameInfo/Players.add_child(new_ui)
		i += 1
	for child in $GameInfo/Players.get_children():
		child.size_flags_horizontal = 4

func update_colors_ui() -> void:
	for col_butt in $ColorSelection.get_children():
		if col_butt is Color_Button:
			col_butt.set_covered(false)
	
	for player in GameData.players:
		if player.color != Color.AZURE:
			$ColorSelection.get_child(1 + GameData.COLORS.find(player.color)).set_covered(true)

func on_color_button_pressed(color: Color) -> void:
	print("BUTTON_PRESSED")
	send_updated_color.rpc(color, GameData.loc_player_ind)

@rpc("any_peer","call_local")
func send_updated_color(color: Color, index: int) -> void:
	GameData.players[index].color = color
	update_players_ui()
	update_colors_ui()

@rpc("authority", "call_remote")
func send_lobby_data(players_as_json: Array, my_index: int, rnd_deployment: bool) -> void:
	GameData.players.clear()
	GameData.players = GameData.players_from_JSON(players_as_json)
	GameData.loc_player_ind = my_index
	# Update UI
	update_ui()
	toggle_random_deployment(rnd_deployment)

func on_peer_disconnected(_id: int) -> void:
	if _id == 0:
		on_back_button_pressed()
		return
	
	var is_not_id: Callable = func (player: Player):
		return player.id != _id
	print(GameData.players_to_string())
	GameData.players = GameData.players.filter(is_not_id)
	update_ui()
	print(GameData.players_to_string())

func on_disconnected_from_server() -> void:
	$GameInfo/Status.add_theme_color_override("font_color", Color.RED)
	$GameInfo/Status.text = "Disconnected"
	$GameInfo/StatusReason.show()
	$GameInfo/StatusReason.add_theme_color_override("font_color", Color.RED)
	$GameInfo/StatusReason.text = client.disconnected_reason

func on_connected_to_server() -> void:
	$GameInfo/Status.add_theme_color_override("font_color", Color.GREEN)
	$GameInfo/Status.text = "Connected"
	$GameInfo/StatusReason.hide()

func on_random_deployment_toggled(_newVal: bool) -> void:
	if GameData.multiplayer.is_server():
		random_deployment = true
		toggle_random_deployment.rpc(_newVal)

func on_start_button_pressed() -> void:
	if GameData.multiplayer.is_server():
		start_game.rpc()

@rpc("call_local", "authority")
func start_game() -> void:
	print("start_game()")

@rpc("call_remote", "authority")
func toggle_random_deployment(_new_val: bool) -> void:
	random_deployment = _new_val
	$RandomDeployment.button_pressed = _new_val

func on_back_button_pressed() -> void:
	GameData.cur_phase = GameData.Phase.main_menu
	var local_name: String = GameData.players[GameData.loc_player_ind].name
	GameData.players.clear()
	GameData.players.append(Player.new(0, local_name, Color.AZURE))
	client.close_connection()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
