extends Control

func _ready() -> void:
	$Join.pressed.connect(_on_join_pressed)
	$Host.pressed.connect(_on_host_pressed)
	$ServerAddress.placeholder_text = GameData.server_addr
	$PlayerName.placeholder_text = GameData.players[0].name

func _on_join_pressed() -> void:
	if $ServerAddress.text == "":
		$ServerAddress.text = $ServerAddress.placeholder_text
	if $PlayerName.text == "":
		$PlayerName.text = $PlayerName.placeholder_text
	if len($PlayerName.text) > 9 or not $ServerAddress.text.is_valid_ip_address():
		return
	GameData.players.clear()
	GameData.players.append(GameData.Player.new(0, $PlayerName.text, Color.AZURE))
	GameData.client.make_client($ServerAddress.text)
	await GameData.client.connected_to_server
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_host_pressed() -> void:
	if $ServerAddress.text == "":
		$ServerAddress.text = $ServerAddress.placeholder_text
	if $PlayerName.text == "":
		$PlayerName.text = $PlayerName.placeholder_text
	GameData.players.clear()
	GameData.players.append(GameData.Player.new(0, $PlayerName.text, Color.AZURE))
	GameData.client.make_server($ServerAddress.text)
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")
