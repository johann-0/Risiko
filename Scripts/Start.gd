extends Control
var startedUp: bool = false

func _ready():
	$join.connect("pressed", Callable(self, "_on_join_pressed"))
	$host.connect("pressed", Callable(self, "_on_host_pressed"))

func startUp():
	get_parent().playerName = ""
	get_parent().serverName = ""
	$playerName.text = "Jose"
	$serverName.text = "BestServer"
	startedUp = true
	show()

func _on_join_pressed():
	get_parent().playerName = $playerName.text
	get_parent().serverName = $serverName.text
	startedUp = false
	hide()
	get_parent().get_child(1).startUp(false)

func _on_host_pressed():
	get_parent().playerName = $playerName.text
	get_parent().serverName = $serverName.text
	startedUp = false
	hide()
	get_parent().get_child(1).startUp(true)
