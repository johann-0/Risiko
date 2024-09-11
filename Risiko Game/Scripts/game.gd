extends Node2D

var client: UDP_client = GameData.client

func _ready() -> void:
	# Connect functions
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)

func _unhandled_input(_event) -> void:
	pass

func client_connected() -> void:
	pass
func client_disconnected() -> void:
	pass
func client_connecting() -> void:
	pass
func client_rec_data(data_str: String) -> void:
	pass
