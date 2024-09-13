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
	set_status("", "", Color.BLACK)

func _on_join_pressed() -> void:
	if $EnterInfo/Player/PlayerName["theme_override_colors/font_color"] == Color.RED:
		return
	GameData.players.clear()
	GameData.players.append(Player.new(0, player_lab.text, Color.AZURE))
	client.make_client(address_lab.text)
	set_status("Trying to connect to server...", "", Color.YELLOW)
	await AwaitMultiple.new(true, [client.connected_to_server, GameData.client.connection_failed \
	  , get_tree().create_timer(5.0).timeout], [0,0,0]).completed
	if client.peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED:
		GameData.cur_phase = GameData.Phase.lobby
		get_tree().change_scene_to_file("res://Scenes/lobby.tscn")
	else:
		set_status("Can't connect to server", GameData.client.disconnected_reason, Color.RED)

func set_status(status: String, reason: String, color: Color) -> void:
	if status == "":
		$Bottom/Status.hide()
		$Bottom/Reason.hide()
		return
	$Bottom/Status.show()
	$Bottom/Status.add_theme_color_override("font_color", color)
	$Bottom/Status.text = status
	if reason == "":
		$Bottom/Reason.hide()
		return
	$Bottom/Reason.show()
	$Bottom/Reason.add_theme_color_override("font_color", color)
	$Bottom/Reason.text = reason

func _on_host_pressed() -> void:
	if $EnterInfo/Address/Address["theme_override_colors/font_color"] == Color.RED:
		print("its red")
		return
	GameData.players.clear()
	GameData.players.append(Player.new(1, player_lab.text, Color.AZURE))
	client.make_server(address_lab.text)
	GameData.cur_phase = GameData.Phase.lobby
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_player_text_changed(_newText: String) -> void:
	if player_lab.text.length() <= 16:
		player_lab.remove_theme_color_override("font_color")
	else:
		player_lab.add_theme_color_override("font_color", Color.RED)

func _on_address_text_changed(_newText: String) -> void:
	if address_lab.text.is_valid_ip_address() or (address_lab.text.is_valid_int() \
	 and int(address_lab.text) >= 100 and int(address_lab.text) <= 65535):
		address_lab.remove_theme_color_override("font_color")
	else:
		address_lab.add_theme_color_override("font_color", Color.RED)
