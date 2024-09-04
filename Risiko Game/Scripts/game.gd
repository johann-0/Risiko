extends Node2D

var client: GameData.Client = GameData.client

func _ready():
	# Reset the GameData
	for province in GameData.provinces:
		province.updateInfo(-1, 0, 0)
	
	# Connect functions
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)
	GameData.newTurnPlayerIndex.connect(on_new_turn)
	
	# First turn has started
	on_new_turn(-1, GameData.turnPlayerIndex)

func on_new_turn(oldPlayerIndex: int, newPlayerIndex: int):
	match GameData.gamePhase:
		GameData.Phase.INIT_DEPLOY:
			if GameData.players[newPlayerIndex]._soldiers > 0:
				GameData.players[newPlayerIndex]._soldiers -= 1
				GameData.turnAvailSoldiers = 1

func _unhandled_input(event):
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and GameData.selectedProvID != GameData.Province.WASTELAND_ID \
	  and (GameData.gamePhase == GameData.Phase.INIT_DEPLOY \
	  or GameData.gamePhase == GameData.Phase.DEPLOY):
		if event.is_action_pressed("up") \
		  and GameData.turnAvailSoldiers != 0:
			GameData.provinces[GameData.selectedProvID].addDeploy(GameData.localPlayerIndex)
			GameData.turnAvailSoldiers -= 1
			pass
		elif event.is_action_pressed("down") \
		  and GameData.provinces[GameData.selectedProvID]._to_add != 0:
			GameData.provinces[GameData.selectedProvID].removeDeploy(GameData.localPlayerIndex)
			GameData.turnAvailSoldiers += 1
			pass
	return

func _process(_delta):
	pass#print(GameData.players[0]._soldiers)

func client_connected():
	pass
func client_disconnected():
	pass
func client_connecting():
	pass
func client_rec_data(data: String):
	var json_obj = JSON.parse_string(data)
	match json_obj["message_type"]:
		"prov_selected":
			GameData.gameSelectedProvID = json_obj["data"]["newProvID"]
		_:
			pass
