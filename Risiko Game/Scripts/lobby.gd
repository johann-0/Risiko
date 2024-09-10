extends Control

const RECONNECT_TIMEOUT: float = 3.0

var client: GameData.Client

func _ready() -> void:
	# Initializing
	client = GameData.client

func client_connected():
	$Status.text = "Connected"

func client_disconnected():
	$Status.text = "Disconnected"

func client_connecting():
	$Status.text = "Connecting"

func client_rec_data(data: String) -> void:
	pass

func _on_random_deployment_pressed(newVal: bool) -> void:
	pass

func _on_start_button_pressed() -> void:
	pass

func _on_back_button_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
