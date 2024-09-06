extends Node2D

var client: GameData.Client = GameData.client

func _ready():
	# Connect functions
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)
	GameData.newTurn.connect(on_new_turn)
	$Control/Screen/EndTurn.pressed.connect(_on_end_turn_clicked)
	
	# (Re)Set the GameData
	var player_index = GameData.turnPlayerIndex
	GameData.turnPlayerIndex = -1
	if GameData.randomDeployment == true:
		# Update the provinces
		for prov in GameData.provinces:
			print(prov._to_string())
			prov.infoUpdated.emit(prov._id)
		GameData.setNewTurn(player_index, GameData.Phase.deploy)
	else:
		GameData.setNewTurn(player_index, GameData.Phase.init_deploy)
	
	
	# First turn has started
	
	# DEBUG
	print("STARTING DEBUG STUFF")
	for i in range(GameData.NUM_PROV - 1):
		GameData.selectedProvID = i
		await get_tree().create_timer(0.3).timeout
		GameData.provinces[i].addDeploy(0)
		await get_tree().create_timer(0.3).timeout
		_on_end_turn_clicked()
		await get_tree().create_timer(0.3).timeout
		GameData.turnPlayerIndex = 0
		await get_tree().create_timer(0.3).timeout

func on_new_turn(oldIndex: int, newIndex: int, indexChanged: bool\
				, oldPhase: GameData.Phase, newPhase: GameData.Phase, phaseChanged: bool):
	match newPhase:
		GameData.Phase.init_deploy:
			for province in GameData.provinces:
				province.commitDeployment()
			GameData.turnAvailSoldiers = 1
		GameData.Phase.deploy:
			for province in GameData.provinces:
				province.commitDeployment()
		GameData.Phase.attack:
			pass
		_:
			pass
	$Control.on_new_turn(oldIndex, newIndex, indexChanged, oldPhase, newPhase, phaseChanged)

func _unhandled_input(event):
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and GameData.selectedProvID != GameData.Province.WASTELAND_ID \
	  and (GameData.gamePhase == GameData.Phase.init_deploy \
	  or GameData.gamePhase == GameData.Phase.deploy):
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
	pass

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
			GameData.setNewTurn(data["new_player_id"], GameData.Phase.get(data["phase"]))
			GameData.turnAvailSoldiers = data["avail_soldiers"]
			if GameData.turnPlayerIndex == GameData.localPlayerIndex:
				GameData.selectedProvID = GameData.selectedProvID
		_:
			print("")

func _on_end_turn_clicked():
	# Make sure player is allowed to end their turn
	match GameData.gamePhase:
		GameData.Phase.deploy:
			if GameData.turnAvailSoldiers != 0: return
		GameData.Phase.init_deploy:
			if GameData.turnAvailSoldiers != 0: return
		_:
			pass
	client._send_dict({"message_type": "end_turn"})
