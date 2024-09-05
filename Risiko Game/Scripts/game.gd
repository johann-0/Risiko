extends Node2D

var client: GameData.Client = GameData.client

func _ready():
	# Reset the GameData
	if GameData.randomDeployment != true:
		for province in GameData.provinces:
			province._owner = -1
			province._soldiers = 0
			province._to_add = 0
	else:
		for province in GameData.provinces:
			print(province._to_string())
			province.updateInfo(province._owner, 1, 0)
	
	# Connect functions
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)
	GameData.newTurnPlayerIndex.connect(on_new_turn)
	$Control/Screen/EndTurn.pressed.connect(_on_end_turn_clicked)
	
	# First turn has started
	GameData.turnPlayerIndex = GameData.turnPlayerIndex

func on_new_turn(oldPlayerIndex: int, newPlayerIndex: int):
	print("new turn")
	match GameData.gamePhase:
		GameData.Phase.INIT_DEPLOY:
			for province in GameData.provinces:
				province.commitDeployment()
			if GameData.players[newPlayerIndex]._soldiers > 0:
				GameData.players[newPlayerIndex]._soldiers -= 1
				GameData.turnAvailSoldiers = 1
				$Control.newTurn(oldPlayerIndex, newPlayerIndex)

func _unhandled_input(event):
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and GameData.selectedProvID != GameData.Province.WASTELAND_ID \
	  and (GameData.gamePhase == GameData.Phase.INIT_DEPLOY \
	  or GameData.gamePhase == GameData.Phase.DEPLOY):
		if event.is_action_pressed("up") \
		  and GameData.turnAvailSoldiers != 0:
			GameData.provinces[GameData.selectedProvID].addDeploy(GameData.localPlayerIndex)
		elif event.is_action_pressed("down") \
		  and GameData.provinces[GameData.selectedProvID]._to_add != 0:
			GameData.provinces[GameData.selectedProvID].removeDeploy(GameData.localPlayerIndex)
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and event.is_action_pressed("escape"):
		GameData.selectedProvID = GameData.Province.WASTELAND_ID

func _process(_delta):
	pass#print(GameData.players[0]._soldiers)

func client_connected():
	pass
func client_disconnected():
	pass
func client_connecting():
	pass
func client_rec_data(data_str: String):
	var json_obj = JSON.parse_string(data_str)
	var data = json_obj["data"]
	match json_obj["message_type"]:
		"prov_selected":
			var newProvID = data["newProvID"]
			GameData.gameSelectedProvID = newProvID
			print("Prov selected: " + str(newProvID))
		"prov_updated":
			GameData.turnAvailSoldiers = data["avail_soldiers"]
			if GameData.turnPlayerIndex != GameData.localPlayerIndex:
				var prov_ = data["prov"]
				var prov: GameData.Province = GameData.provinces[prov_["id"]]
				prov._soldiers = prov_["soldiers"]
				prov.updateInfo(prov_["owner"], prov_["soldiers"], prov_["to_add"])
			print("Prov updated: " + str(GameData.provinces[data["prov"]["id"]]))
		"end_turn":
			GameData.turnPlayerIndex = data["new_prov_id"]
			GameData.turnAvailSoldiers = data["avail_soldiers"]
			if GameData.turnPlayerIndex == GameData.localPlayerIndex:
				GameData.selectedProvID = GameData.selectedProvID
		_:
			print("")

func _on_end_turn_clicked():
	print("End turn button clicked!")
	# Make sure player is allowed to end their turn
	if GameData.turnAvailSoldiers != 0:
		return
	client._send_dict({"message_type": "end_turn"})
