extends Node2D
var serverName: String
var playerName: String

func _ready():
	$Start.show()
	$Lobby.hide()
	$Start.startUp()

