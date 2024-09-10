extends Node

var peer: ENetMultiplayerPeer = null
@onready var g_multiplayer = GameData.multiplayer

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connected_to_server()
signal connection_failed()
signal disconnected_from_server()

func _ready() -> void:
	g_multiplayer.peer_connected.connect(on_peer_connected) # Everyone receives this
	g_multiplayer.peer_disconnected.connect(on_peer_disconnected) # Everyone receives this
	g_multiplayer.connected_to_server.connect(on_connected_to_server) # Only clients
	g_multiplayer.connection_failed.connect(on_connection_failed) # Only clients
	g_multiplayer.server_disconnected.connect(on_disconnected_from_server) # Only clients

func id_print(text: String) -> void:
	print("[" + str(g_multiplayer.get_unique_id()) + "] " + text)

func on_peer_connected(_id: int) -> void:
	id_print("peer_connected: " + str(_id))
	peer_connected.emit(_id)

func on_peer_disconnected(_id: int) -> void:
	id_print("peer_disconnected: " + str(_id))
	peer_disconnected.emit(_id)

func on_connected_to_server() -> void:
	id_print("connected_to_server")
	connected_to_server.emit()

func on_connection_failed() -> void:
	id_print("connection_failed")
	connection_failed.emit()

func on_disconnected_from_server() -> void:
	id_print("server_disconnected")
	disconnected_from_server.emit()

func close_connection() -> void:
	peer.close()
	g_multiplayer.multiplayer_peer = null

func make_server(address: String) -> void:
	print("Starting server: " + address)
	GameData.server_addr = address
	peer = ENetMultiplayerPeer.new()
	var port: String = ""
	for i in range(address.length()):
		var cha = address[len(address) - 1 - i]
		if cha == ":":
			break
		else:
			port += cha
	port = port.reverse()
	#peer.set_bind_ip("127.0.0.1") # DEBUG
	var err: Error = peer.create_server(int(port), 3) # Maximum of 3 peers (total: 4 players).
	if err != OK:
		# Is another server running?
		printerr("Error hosting! (" + str(err) + ")")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_ZSTD)
	g_multiplayer.set_multiplayer_peer(peer)
	id_print("Server started: " + str(IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)))

func make_client(address: String) -> void:
	GameData.server_addr = address
	print("Client connecting to: " + address)
	peer = ENetMultiplayerPeer.new()
	var port: String = ""
	var n: int = address.length()
	for i in range(n):
		var cha = address[address.length() - 1]
		address = address.substr(0, address.length() - 1)
		if cha == ":":
			break
		else:
			port += cha
	port = port.reverse()
	var err: Error = peer.create_client(address, int(port))
	if err != OK:
		printerr("Error while creating client (" + str(err) + ")")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_ZSTD)
	g_multiplayer.set_multiplayer_peer(peer)
