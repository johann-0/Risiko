extends Control

const RECONNECT_TIMEOUT: float = 3.0

var client: UDP_client = GameData.client
var random_deployment: bool = false

func _ready() -> void:
	$Back.pressed.connect(on_back_button_pressed)
	$Start.pressed.connect(on_start_button_pressed)
	$RandomDeployment.toggled.connect(on_random_deployment_toggled)
	if not GameData.multiplayer.is_server():
		$RandomDeployment.disabled = true
	
	$GameInfo/Name/PlayerName.text = GameData.players[0].name
	$GameInfo/Server/ServerName.text = GameData.server_addr
	on_connected_to_server()
	
	#client.peer_connected.connect(on_peer_connected)
	#client.peer_disconnected.connect(on_peer_disconnected)
	#client.connected_to_server.connect()
	client.disconnected_from_server.connect(on_disconnected_from_server)
	
	# Send player data to the everyone else
	if not GameData.multiplayer.is_server():
		send_player_name.rpc_id(1, GameData.players[0].name)
	else:
		update_players_ui()

@rpc("any_peer", "call_remote")
func send_player_name(player_name: String) -> void:
	if GameData.multiplayer.is_server():
		GameData.players.append(Player.new(GameData.players.size(), player_name, Color.AZURE))
		# Send lobby data to everyone
		send_lobby_data.rpc(GameData.gplayers_to_JSON())
		# Update UI
		update_players_ui()

func update_players_ui() -> void:
	for child in $GameInfo/Players.get_children():
		child.queue_free()
	var i: int = 0
	for player in GameData.players:
		var new_ui: Player_UI = Player_UI.new_player_UI(Vector2i(0,20*i), player.name, Color.AZURE)
		$GameInfo/Players.add_child(new_ui)
		i += 1

@rpc("authority", "call_remote")
func send_lobby_data(players_as_json: Array):
	GameData.players.clear()
	GameData.players = GameData.players_from_JSON(players_as_json)
	# Update UI
	update_players_ui()

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
		random_deployment_toggled.rpc()

func on_start_button_pressed() -> void:
	if GameData.multiplayer.is_server():
		start_game.rpc()

@rpc("call_local", "authority")
func start_game() -> void:
	
	pass

@rpc("call_remote", "authority")
func random_deployment_toggled() -> void:
	random_deployment = not random_deployment
	$RandomDeployment.button_pressed = not $RandomDeployment.button_pressed

func on_back_button_pressed() -> void:
	GameData.cur_phase = GameData.Phase.main_menu
	client.close_connection()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
