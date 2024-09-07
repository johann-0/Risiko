extends Control

func _ready():
	$Join.connect("pressed", Callable(self, "_on_join_pressed"))
	$Host.connect("pressed", Callable(self, "_on_host_pressed"))
	
	var defPlayer = GameData.Player.DEFAULT_PLAYER()
	var defServerName = GameData.ServerName.DEFAULT_SERVER_NAME()
	
	GameData.players[GameData.localPlayerIndex]._name = defPlayer._name
	GameData.serverName = defServerName
	$PlayerName.text = defPlayer._name
	$ServerAddress.text = defServerName._address
	$ServerPort.text = str(defServerName._port)
	
	if GameData.DEBUG_MODE == true:
		await get_tree().create_timer(0.3).timeout
		_on_join_pressed()

func _on_join_pressed():
	if len($PlayerName.text) > 9:
		return
	GameData.players[GameData.localPlayerIndex]._name = $PlayerName.text
	GameData.serverName = GameData.ServerName.new($ServerAddress.text, int($ServerPort.text))
	get_tree().change_scene_to_file("res://Scenes/lobby.tscn")

func _on_host_pressed():
	GameData.players[GameData.localPlayerIndex]._name = $PlayerName.text
	GameData.serverName = GameData.ServerName.new($ServerAddress.text, int($ServerPort.text))
	$Host.hide()
	#get_tree().change_scene_to_file("res://Scenes/lobby.tscn")
