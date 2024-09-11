extends Control

@onready var client: UDP_client = GameData.client
@onready var player_lab: LineEdit = $EnterInfo/Player/PlayerName
@onready var address_lab: LineEdit = $EnterInfo/Address/Address
@onready var join_but: Button = $Bottom/Buttons/Join
@onready var host_but: Button = $Bottom/Buttons/Host

func _ready() -> void:
	join_but.pressed.connect(_on_join_pressed)
	host_but.pressed.connect(_on_host_pressed)
	player_lab.text_changed.connect(_on_player_text_changed)
	address_lab.text_changed.connect(_on_address_text_changed)
	address_lab.text = GameData.server_addr
	player_lab.text = GameData.players[0].name

func _on_join_pressed() -> void:
	if len(player_lab.text) > 9 or not address_lab.text.is_valid_ip_address():
		return
	GameData.players.clear()
	GameData.players.append(Player.new(0, player_lab.text, Color.AZURE))
	client.make_client(address_lab.text)
	await AwaitMultiple.new(true, [client.connected_to_server, GameData.client.connection_failed \
	  , get_tree().create_timer(5.0).timeout], [0,0,0]).completed
	if client.peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		GameData.cur_phase = GameData.Phase.lobby
		get_tree().change_scene_to_file("res://Scenes/lobby.tscn")
	else:
		pass # TODO err message

func _on_host_pressed() -> void:
	GameData.players.clear()
	GameData.players.append(Player.new(0, player_lab.text, Color.AZURE))
	client.make_server(address_lab.text)
	GameData.cur_phase = GameData.Phase.lobby
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_player_text_changed(_newText: String) -> void:
	if player_lab.text.length() <= 16:
		player_lab.remove_theme_color_override("font_color")
	else:
		if not player_lab.has_theme_color_override("font_color"):
			player_lab.add_theme_color_override("font_color", Color.RED)

func _on_address_text_changed(_newText: String) -> void:
	if address_lab.text.is_valid_ip_address():
		if address_lab.has_theme_color_override("font_color"):
			address_lab.remove_theme_color_override("font_color")
	else:
		if not address_lab.has_theme_color_override("font_color"):
			address_lab.add_theme_color_override("font_color", Color.RED)
