extends Control

const RECONNECT_TIMEOUT: float = 3.0

var _startedUp: bool = false

const Client = preload("res://Scripts/WS_client.gd")
var _client: Client = Client.new()

func _ready():
	$Back.pressed.connect(_on_back_button_pressed)
	$Start.pressed.connect(_on_start_button_pressed)
	$GameInfo/PlayerName.text += GameData.players[GameData.localPlayerIndex]._name
	$GameInfo/ServerName.text += GameData.serverName.getName()
	
	_client.connected.connect(client_connected)
	_client.disconnected.connect(client_disconnected)
	_client.recieved_data.connect(client_rec_data)
	_client.connecting.connect(client_connecting)
	
	add_child(_client)
	
	# Initiate connection to the given URL.
	_client._connect_to_url(GameData.serverName.getName())
	
	await _client.connected
	# Send data.
	_client._socket.send_text(JSON.stringify({
		"message_type": "message",
		"data": "Hello from a client!"
		}))
	
	# Send player data to the server
	var playerData = {
		"message_type": "player_info",
		"data": {
				"name": GameData.players[GameData.localPlayerIndex]._name,
				"color": GameData.players[GameData.localPlayerIndex]._color.to_rgba32()
			}
		}
	_client._send_dict(playerData)

func _process(_delta):
	pass

func connect_after_timeout(timeout: float):
	await get_tree().create_timer(timeout).timeout # Delay for timeout
	_client._connect_to_url(GameData.serverName.getName())

func client_connected():
	$Status.text = "Connected"

func client_disconnected():
	$Status.text = "Disconnected"
	#connect_after_timeout(RECONNECT_TIMEOUT)

func client_connecting():
	$Status.text = "Connecting"

func client_rec_data(data: String):
	var json_obj = JSON.parse_string(data)
	match json_obj["message_type"]:
		"message":
			print("Recieved message")
		"lobby_data":
			print("Recieved lobby_data")
			GameData.players.clear()
			for obj in json_obj["data"]:
				var newPlayer = GameData.Player.new(obj["id"], obj["name"], Color.hex(obj["color"]))
				GameData.players.append(newPlayer)
			print("GameData.players: ", GameData.players)
			# Update the UI
			var displayText: String = ""
			for player in GameData.players:
				displayText += "[" + str(player._id) + "] " + player._name + "\n"
			$GameInfo/Players.text = "Players:\n" + displayText
		_:
			print("Recieved unknown(%s)" % [json_obj["message_type"]])

func _on_start_button_pressed():
	# Debugging stuff
	#printID("Start button bressed!")
	#var index: int = 0
	#for player in GameData.players:
		#printID(str(index) + ": " + str(player._id))
		#index += 1
	
	# Call start game on all machines
	pass

func _on_back_button_pressed():
	_client._disconnect_from_url()
	# Delete lobby data
	GameData.players.clear()
	GameData.players.append(GameData.Player.DEFAULT_PLAYER())
	GameData.localPlayerIndex = 0
	
	if _client._state != WebSocketPeer.STATE_CLOSED:
		await _client.disconnected
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func printID(text: String):
	print("[" + str(multiplayer.get_unique_id()) + "] " + text)
