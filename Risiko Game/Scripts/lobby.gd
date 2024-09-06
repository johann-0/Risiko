extends Control

const RECONNECT_TIMEOUT: float = 3.0

var _client: GameData.Client

func _ready():
	# Initializing
	_client = GameData.client
	# General UI stuff
	GameData.randomDeploymentChanged.connect(_on_random_deployment_changed)
	$RandomDeployment.toggled.connect(_on_random_deployment_pressed)
	$Back.pressed.connect(_on_back_button_pressed)
	$Start.pressed.connect(_on_start_button_pressed)
	var player: GameData.Player = GameData.players[GameData.localPlayerIndex]
	$GameInfo/PlayerName.text += player._name
	$GameInfo/ServerName.text += GameData.serverName.getName()
	# UI stuff: color picking
	var but_col = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW, Color.AZURE]
	for i in range(5):
		var newBut = Color_Button.new_color_button(Vector2i(0, i * (24 + 2)), but_col[i])
		newBut.button_pressed.connect(on_color_button_pressed)
		$ColorSelection.add_child(newBut)
	
	_client.connected.connect(client_connected)
	_client.disconnected.connect(client_disconnected)
	_client.received_data.connect(client_rec_data)
	_client.connecting.connect(client_connecting)
	
	# Initiate connection to the given URL.
	_client._connect_to_url(GameData.serverName.getName())
	await _client.connected
	
	# Check we are connected
	_client._send_dict({
		"message_type": "message",
		"data": "Hello from a client!"
		})
	
	# Send player data to the server
	_client._send_dict({
		"message_type": "player_info",
		"data": {
				"name": GameData.players[GameData.localPlayerIndex]._name,
				"color": GameData.players[GameData.localPlayerIndex]._color.to_rgba32()
			}
		})

func on_color_button_pressed(color: Color):
	_client._send_dict({
		"message_type": "lobby_updated", # used to be "color_selected"
		"data": {
			"color": color.to_rgba32(),
			"random_deployment": GameData.randomDeployment
		}
	})

func connect_after_timeout(timeout: float):
	await get_tree().create_timer(timeout).timeout # Delay for timeout
	_client._connect_to_url(GameData.serverName.getName())

func client_connected():
	$Status.text = "Connected"

func client_disconnected():
	$Status.text = "Disconnected"

func client_connecting():
	$Status.text = "Connecting"

func client_rec_data(data: String):
	var json_obj = JSON.parse_string(data)
	match json_obj["message_type"]:
		"message":
			print("Received message")
		"lobby_data":
			print("Received lobby_data")
			GameData.players.clear()
			GameData.localPlayerIndex = 0
			for child in $GameInfo/Players.get_children():
				child.queue_free()

			for obj in json_obj["data"]:
				var newPlayer = GameData.Player.new(obj["id"], obj["name"], Color.hex(obj["color"]))
				GameData.players.append(newPlayer)
			GameData.localPlayerIndex = json_obj["index"]
			GameData.randomDeployment = json_obj["random_deployment"]
			print("GameData.players: ", GameData.players)
			# Update the UI
			var localPlayer = GameData.players[GameData.localPlayerIndex]
			$GameInfo/PlayerName.text = "Your Name: " + \
				GameData.players[GameData.localPlayerIndex]._name + \
				" [" + str(localPlayer._id) + "]"
			var index: int = 0
			for player in GameData.players:
				var player_obj = Player_UI.new_player_UI(\
					Vector2i(0, 0 + 12 + 14 * index), \
					player._id, player._name, player._color)
				$GameInfo/Players.add_child(player_obj)
				# Highlight the local player's stats
				if index == GameData.localPlayerIndex:
					player_obj.setTextColor(Color.GREEN)
				index += 1
			for i in range(5):
				$ColorSelection.get_child(i).setCovered(false)
			# Check which colors are already picked
			for player in GameData.players:
				match player._color:
					Color.BLUE:
						$ColorSelection.get_child(0).setCovered(true)
					Color.RED:
						$ColorSelection.get_child(1).setCovered(true)
					Color.GREEN:
						$ColorSelection.get_child(2).setCovered(true)
					Color.YELLOW:
						$ColorSelection.get_child(3).setCovered(true)
					_: # Random is selected (Azure)
						pass
		"start_game":
			GameData.turnPlayerIndex = json_obj["turn"]
			print("Starting game: %s", GameData.players_to_string())
			get_tree().change_scene_to_file("res://Scenes/game.tscn")
		"start_game_rand":
			GameData.turnPlayerIndex = json_obj["turn"]
			# Update province owners
			var prov_owners = json_obj["prov_owners"]
			var index = 0
			for province in GameData.provinces:
				province._owner = prov_owners[index]
				province._soldiers = 1
				index += 1
			print("Starting game_rand: %s", GameData.players_to_string())
			get_tree().change_scene_to_file("res://Scenes/game.tscn")
		_:
			print("Received unknown(%s)" % [json_obj["message_type"]])

func _on_random_deployment_changed():
	$RandomDeployment.button_pressed = GameData.randomDeployment

func _on_random_deployment_pressed(newVal: bool):
	GameData.randomDeployment = newVal
	_client._send_dict({"message_type": "lobby_updated", # used to be "color_selected"
		"data": {
			"color": GameData.players[GameData.localPlayerIndex]._color.to_rgba32(),
			"random_deployment": GameData.randomDeployment
		}
		})

func _on_start_button_pressed():
	_client._send_dict({
		"message_type": "start_game"
		})

func _on_back_button_pressed():
	_client._disconnect_from_url()
	# Delete lobby data
	GameData.players.clear()
	GameData.players.append(GameData.Player.DEFAULT_PLAYER())
	GameData.localPlayerIndex = 0
	
	if _client._state != WebSocketPeer.STATE_CLOSED:
		await _client.disconnected
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
