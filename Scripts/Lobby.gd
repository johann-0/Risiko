extends Control

@export var ADDRESS: String = "172.0.0.1"
@export var PORT: int = 8910
var peer: ENetMultiplayerPeer
var startedUp: bool = false

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func startUp(isHosting: bool):
	if isHosting:
		hostGame()
		SendPlayerInformation(get_parent().playerName, multiplayer.get_unique_id())
	else:
		peer = ENetMultiplayerPeer.new()
		peer.create_client(ADDRESS, PORT)
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
	
	startedUp = true

# Called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))

# Called on the server and clients
func peer_disconnected(id):
	print("Player disconnected: " + str(id))
	GameData.players.erase(id)

# Called only from clients
func connected_to_server():
	print("Connected to server!")
	# Send player id and name to server
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

# Called only from clients
func connection_failed():
	print("Error: Failed to connect!")

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameData.players.has(id):
		GameData.players.append(GameData.Player.new(id, name))
	
	if multiplayer.is_server():
		for i in GameData.players:
			print((GameData.players[i]))
			print((GameData.players[i])._name)
			SendPlayerInformation.rpc((GameData.players[i])._name, i)

@rpc("any_peer","call_local")
func StartGame():
	var scene = load("res://testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	if error != OK:
		print("cannot host: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")

func _on_start_game_button_down():
	StartGame.rpc()
