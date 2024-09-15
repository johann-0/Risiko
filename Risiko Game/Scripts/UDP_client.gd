class_name UDP_client
extends Node

@onready var peer: ENetMultiplayerPeer = null
@onready var g_multiplayer = GameData.multiplayer
@onready var id: int = 0
@onready var disconnected_reason: String = "unknown"

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

@rpc("authority","call_remote", "reliable")
func disconnecting_from_host(reason: String):
	disconnected_reason = reason
	print("TREASON")

func disconnect_client(_id: int, _reason: String):
	if not g_multiplayer.is_server():
		return
	disconnecting_from_host.rpc_id(_id, _reason)
	await get_tree().create_timer(0.5).timeout
	peer.disconnect_peer(_id)

func on_peer_connected(_id: int) -> void:
	GameData.id_print("peer_connected: " + str(_id))
	peer_connected.emit(_id)
	#if g_multiplayer.is_server(): # DEBUG
		#disconnect_client(_id, "Test") # DEBUG

func on_peer_disconnected(_id: int) -> void:
	GameData.id_print("peer_disconnected: " + str(_id))
	peer_disconnected.emit(_id)

func on_connected_to_server() -> void:
	id = g_multiplayer.get_unique_id()
	GameData.id_print("connected_to_server")
	connected_to_server.emit()

func on_connection_failed() -> void:
	GameData.id_print("connection_failed")
	connection_failed.emit()

func on_disconnected_from_server() -> void:
	GameData.id_print("server_disconnected (" + disconnected_reason + ")")
	id = 0
	disconnected_from_server.emit()

func close_connection() -> void:
	peer.close()
	g_multiplayer.multiplayer_peer = null

func make_server(address: String) -> void:
	var returned: Array[String] = get_port_and_address(address)
	var port: String = returned[0]
	GameData.server_addr = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),IP.TYPE_IPV4) \
	  + ":" + port
	print("Starting server: " + GameData.server_addr)
	g_multiplayer.set_multiplayer_peer(null)
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(int(port), 3) # Maximum of 3 peers (total: 4 players).
	if err != OK:
		# Is another server running?
		printerr("Error hosting! (" + str(err) + ")")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_ZSTD)
	g_multiplayer.set_multiplayer_peer(peer)
	id = g_multiplayer.get_unique_id()
	GameData.id_print("Server started: " + GameData.server_addr)

func make_client(address: String) -> void:
	var returned: Array[String] = get_port_and_address(address)
	var port: String = returned[0]
	address = returned[1]
	GameData.server_addr = address + ":" + port
	print("Client connecting to: " + address)
	g_multiplayer.set_multiplayer_peer(null)
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(address, int(port))
	if err != OK:
		printerr("Error while creating client (" + str(err) + ")")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_ZSTD)
	g_multiplayer.set_multiplayer_peer(peer)
	id = g_multiplayer.get_unique_id()

func get_port_and_address(address: String) -> Array[String]:
	var toReturn: Array[String] = ["",""]
	var port: String = ""
	var n: int = address.length()
	for i in range(n):
		var cur_char = address[address.length() - 1]
		address = address.substr(0, address.length() - 1)
		if cur_char == ":":
			break
		else:
			port += cur_char
	port = port.reverse()
	toReturn[0] = port
	toReturn[1] = address
	return toReturn
