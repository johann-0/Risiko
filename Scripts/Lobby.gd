extends Control

@export var ADDRESS: String = "2a02:908:1060:6aa3:8de2:56d2:e69c:d2b9"
@export var PORT: int = 8910
var peer: ENetMultiplayerPeer
var startedUp: bool = false
var upnp: UPNP

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	$start.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$back.connect("pressed", Callable(self, "_on_back_button_pressed"))

func startUp(isHosting: bool):
	upnp = UPNP.new()
	var error = upnp.add_port_mapping(PORT)
	
	if error != UPNP.UPNP_RESULT_SUCCESS:
		print("Error! Failed to do port mapping!: " + str(error))
		return
	
	
	peer = ENetMultiplayerPeer.new()
	if isHosting:
		error = peer.create_server(PORT, 4)
		if error != OK:
			printID("Error! Failed to create server: " + error)
			return
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
		printID("Hosting IP address under: " + str(IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)))
		printID("Waiting For Players!")
		
		# Set up the players array in GameData
		var playerName: String = GameData.players[GameData.localPlayerIndex]._name
		GameData.localPlayerIndex = 0
		GameData.players.clear()
		GameData.players.append(GameData.Player.new(multiplayer.get_unique_id(), playerName, Color.BLUE))
	else:
		error = peer.create_client(ADDRESS, PORT)
		if error != OK:
			printID("Error! Failed to create client: " + error)
			return
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
	
	$playerName.text = GameData.players[GameData.localPlayerIndex]._name
	$serverName.text = GameData.serverName
	show()
	startedUp = true

# Called on the server and clients
func peer_connected(id):
	printID("Player connected (id: " + str(id) + ")")
# Called on the server and clients
func peer_disconnected(id):
	printID("Player disconnected (id: " + str(id) + ")")
	var index: int = 0
	for players in GameData.players:
		if players._id == id:
			break;
		index += 1
	GameData.players.pop_at(index)
# Called only from clients
func connected_to_server():
	printID("Connected to server!")
	# Send player id and name to the server
	sendPlayerInfoToServer()
	GameData.players.clear()
# Called only from clients
func connection_failed():
	printID("Failed to connect (to server)!")
# IDK who calls this
func server_disconnected():
	printID("Server disconnected!")

func sendPlayerInfoToServer():
	SendPlayerInformation.rpc_id(1, GameData.players[GameData.localPlayerIndex]._name, multiplayer.get_unique_id(), -1)

@rpc("authority", "call_remote")
func SendLocalPlayerIndex(newLocalIndex: int):
	GameData.localPlayerIndex = newLocalIndex

@rpc("any_peer", "call_remote")
func SendPlayerInformation(name: String, id: int, num_of_players: int):
	if multiplayer.is_server():
		# Add the info into the players array
		var newPlayer: GameData.Player = GameData.Player.new(id, name, Color.BLUE)
		
		# Send this new data to all players
		for player in GameData.players:
			if player._id == GameData.players[GameData.localPlayerIndex]._id:
				continue
			SendPlayerInformation.rpc_id(player._id, newPlayer._name, newPlayer._id, -1)
		GameData.players.append(newPlayer)
		
		# Send data of all players to the new player
		for player in GameData.players:
			SendPlayerInformation.rpc_id(newPlayer._id, player._name, player._id, -1)
		SendLocalPlayerIndex.rpc_id(newPlayer._id, GameData.players.size() - 1)
	else:
		printID("Player info received!")
		GameData.players.append(GameData.Player.new(id, name, Color.BLUE))

@rpc("any_peer","call_local")
func StartGame():
	var scene = load("res://testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()


func _on_start_button_pressed():
	# Debugging stuff
	printID("start button bressed!")
	var index: int = 0
	for player in GameData.players:
		printID(str(index) + ": " + str(player._id))
		index += 1
	# Call start game on all machines
	#StartGame.rpc()

func _on_back_button_pressed():
	# Disconnect the player from the server
	peer.close()
	GameData.players.clear()
	GameData.players.append(GameData.Player.PLACEHOLDER())
	GameData.localPlayerIndex = 0
	#To close a specific port (e.g. after you have finished using it):
	upnp.delete_port_mapping(PORT)
	hide()
	get_parent().get_child(0).startUp()

func printID(text: String):
	print("[" + str(multiplayer.get_unique_id()) + "] " + text)
