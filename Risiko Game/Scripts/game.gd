extends Node2D

var client: GameData.Client = GameData.client

func _ready():
	# Connect functions
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)
	GameData.newTurn.connect(on_new_turn)
	GameData.newGameAttackedProvince.connect(on_new_game_attacked_prov)
	$Control/Screen/EndTurn.pressed.connect(_on_end_turn_clicked)
	
	# (Re)Set the GameData
	var player_index = GameData.turnPlayerIndex
	GameData.turnPlayerIndex = -1
	if GameData.randomDeployment == true:
		# Update the provinces
		for prov in GameData.provinces:
			#print(prov._to_string()) # DEBUG
			prov.infoUpdated.emit(prov._id)
		GameData.setNewTurn(player_index, GameData.Phase.deploy)
	else:
		GameData.setNewTurn(player_index, GameData.Phase.init_deploy)
	
	
	# First turn has started
	
	# DEBUG
	#print("STARTING DEBUG STUFF")
	#for i in range(GameData.NUM_PROV - 1):
		#GameData.selectedProvID = i
		#await get_tree().create_timer(0.3).timeout
		#GameData.provinces[i].addDeploy(0)
		#await get_tree().create_timer(0.3).timeout
		#_on_end_turn_clicked()
		#await get_tree().create_timer(0.3).timeout
		#GameData.turnPlayerIndex = 0
		#await get_tree().create_timer(0.3).timeout

func on_new_turn(oldIndex: int, newIndex: int, indexChanged: bool\
				, oldPhase: GameData.Phase, newPhase: GameData.Phase, phaseChanged: bool):
	match oldPhase:
		GameData.Phase.init_deploy:
			for province in GameData.provinces:
				province.commitDeployment()
		GameData.Phase.deploy:
			for province in GameData.provinces:
				province.commitDeployment()
		GameData.Phase.attack:
			pass
		_:
			pass
	match newPhase:
		GameData.Phase.init_deploy:
			GameData.turnAvailSoldiers = 1
		GameData.Phase.deploy:
			pass
		GameData.Phase.attack:
			if GameData.localPlayerIndex == GameData.turnPlayerIndex:
				GameData.gameAttackedProvID = -1
		GameData.Phase.fortify:
			GameData.already_moved = false
		_:
			pass
	$Control.on_new_turn(oldIndex, newIndex, indexChanged, oldPhase, newPhase, phaseChanged)

func _unhandled_input(event):
	match GameData.gamePhase:
		GameData.Phase.deploy, GameData.Phase.init_deploy:
			if GameData.localPlayerIndex == GameData.turnPlayerIndex \
			  and GameData.selectedProvID != GameData.Province.WASTELAND_ID \
			  and (GameData.provinces[GameData.selectedProvID]._owner == GameData.localPlayerIndex \
			  or GameData.provinces[GameData.selectedProvID]._owner == GameData.Province.WASTELAND_ID):
				if event.is_action_pressed("up") \
				  and GameData.turnAvailSoldiers != 0:
					GameData.provinces[GameData.selectedProvID].addDeploy(GameData.localPlayerIndex)
				elif event.is_action_pressed("down") \
				  and GameData.provinces[GameData.selectedProvID]._to_add != 0:
					GameData.provinces[GameData.selectedProvID].removeDeploy(GameData.localPlayerIndex)
		GameData.Phase.attack:
			if GameData.localPlayerIndex != GameData.turnPlayerIndex:
				return
			elif GameData.diceAreRolling == true \
			  and GameData.provinces[GameData.gameAttackedProvID]._owner == GameData.turnPlayerIndex:
				var att_prov = GameData.provinces[GameData.gameSelectedProvID]
				var def_prov = GameData.provinces[GameData.gameAttackedProvID]
				# Move troop from att_prov to def_prov
				if event.is_action_pressed("up") \
				  and (att_prov._soldiers + att_prov._to_add) > 1:
					att_prov.invade(def_prov._id, true)
				if event.is_action_pressed("down"):
					att_prov.invade(def_prov._id, false)
				if event.is_action_pressed("attack"):
					att_prov.commitDeployment()
					def_prov.commitDeployment()
					GameData.selectedProvID = GameData.gameAttackedProvID # DEBUG
					GameData.gameAttackedProvID = -1 # DEBUG
					GameData.diceAreRolling = false
			elif GameData.gameAttackedProvID != -1:
				var curProv: GameData.Province = GameData.provinces[GameData.gameSelectedProvID]
				if event.is_action_pressed("up") \
				  and curProv._to_add < 3 \
				  and curProv._soldiers > 1:
					curProv.raiseTroops()
				if event.is_action_pressed("down") \
				  and curProv._to_add > 0:
					curProv.lowerTroops()
				if event.is_action_pressed("attack") \
				  and curProv._to_add > 0:
					# ATTACK_PRESSED
					var defProv = GameData.provinces[GameData.gameAttackedProvID]
					# Roll dice
					GameData.diceAreRolling = true
					$Control/Screen/Dice.roll_dice(true)
					client._send_dict({ "message_type": "dice_rolling" })
					await get_tree().create_timer(1.5).timeout
					$Control/Screen/Dice.stop_rolling()
					var dice_results: Array = $Control/Screen/Dice.dice_to_array()
					client._send_dict({ 
						"message_type": "dice",
						"data": { "dice": dice_results }
					})
					await get_tree().create_timer(3).timeout
					var battle_losses = calculateBattle(dice_results)
					if battle_losses[0] != 0:
						curProv.destroyTroops(battle_losses[0])
					if battle_losses[1] != 0:
						defProv.destroyTroops(battle_losses[1])
					# If there are no defenders left, then attacker moves troops there
					if (defProv._soldiers + defProv._to_add) == 0:
						$Control/Screen/Dice.hide_dice()
						defProv.updateInfo(curProv._owner, 0, 1)
						curProv.updateInfo(curProv._owner, 1, curProv._to_add + curProv._soldiers - 2)
						defProv.sendProvToServer()
						curProv.sendProvToServer()
					else:
						GameData.diceAreRolling = false
		GameData.Phase.fortify:
			if GameData.localPlayerIndex != GameData.turnPlayerIndex:
				return
			if GameData.gameAttackedProvID != -1:
				var att_prov = GameData.provinces[GameData.gameAttackedProvID]
				var sel_prov = GameData.provinces[GameData.selectedProvID]
				if event.is_action_pressed("up") and sel_prov._to_add > 0:
					# Move from sel_prov._to_add to att_prov.to_add
					sel_prov.updateInfo(sel_prov._owner, sel_prov._soldiers, sel_prov._to_add - 1)
					att_prov.updateInfo(att_prov._owner, att_prov._soldiers, att_prov._to_add + 1)
					sel_prov.sendProvToServer()
					att_prov.sendProvToServer()
				if event.is_action_pressed("down") and att_prov._to_add > 0:
					sel_prov.updateInfo(sel_prov._owner, sel_prov._soldiers, sel_prov._to_add + 1)
					att_prov.updateInfo(att_prov._owner, att_prov._soldiers, att_prov._to_add - 1)
					sel_prov.sendProvToServer()
					att_prov.sendProvToServer()
				if event.is_action_pressed("attack"):
					if att_prov._to_add > 0:
						sel_prov.commitDeployment()
						att_prov.commitDeployment()
						att_prov.sendProvToServer()
						sel_prov.sendProvToServer()
						GameData.already_moved = true
		_:
			pass
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and event.is_action_pressed("escape"):
		GameData.selectedProvID = GameData.Province.WASTELAND_ID
	if GameData.localPlayerIndex == GameData.turnPlayerIndex \
	  and event.is_action_pressed("endTurn"):
		_on_end_turn_clicked()

# Returns an array. 0th idx is amt of troops att loses, 1st is amt of troops def loses
func calculateBattle(dice: Array): 
	var att_arr: Array = dice.slice(0,3)
	var def_arr: Array = dice.slice(3,5)
	var sort_desc = func (val1: int, val2: int):
		if val1 < val2:
			return false
		return true
	att_arr.sort_custom(sort_desc)
	def_arr.sort_custom(sort_desc)
	print("attackers: " + str(att_arr) + ". defenders: " + str(def_arr))
	var toReturn = [0,0]
	for i in range(def_arr.size()):
		if def_arr[i] == 0:
			continue
		if def_arr[i] >= att_arr[i]:
			toReturn[0] += 1
		else:
			toReturn[1] += 1
	print("result: " + str(toReturn))
	return toReturn

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
		"attack_prov_selected":
			var newProvID = data["newProvID"]
			if GameData.localPlayerIndex != GameData.turnPlayerIndex:
				GameData.gameAttackedProvID = newProvID
				print("Prov attacked: " + str(newProvID))
		"prov_updated":
			GameData.turnAvailSoldiers = data["avail_soldiers"]
			if GameData.turnPlayerIndex != GameData.localPlayerIndex:
				var prov_ = data["prov"]
				var prov: GameData.Province = GameData.provinces[prov_["id"]]
				prov._soldiers = prov_["soldiers"]
				prov.updateInfo(prov_["owner"], prov_["soldiers"], prov_["to_add"])
			print("Prov updated: " + str(GameData.provinces[data["prov"]["id"]]))
		"end_turn":
			GameData.turnAvailSoldiers = data["avail_soldiers"]
			GameData.setNewTurn(data["new_player_id"], GameData.Phase.get(data["phase"]))
			if GameData.turnPlayerIndex == GameData.localPlayerIndex:
				GameData.selectedProvID = GameData.selectedProvID
		"dice":
			if GameData.turnPlayerIndex != GameData.localPlayerIndex:
				if $Control/Screen/Dice.state == $Control/Screen/Dice.State.rolling:
					$Control/Screen/Dice.stop_rolling()
				$Control/Screen/Dice.set_dice(data["dice"])
		"dice_rolling":
			if GameData.turnPlayerIndex != GameData.localPlayerIndex:
				print("ROLING DICEEE")
				$Control/Screen/Dice.roll_dice(true)
		_:
			print("")

func on_new_game_attacked_prov(oldProvID: int, newProvID: int):
	#print("UPDATING DICE!" + str(newProvID)) # DEBUG
	match GameData.gamePhase:
		GameData.Phase.attack:
			$Control.update_dice()
			if GameData.localPlayerIndex == GameData.turnPlayerIndex:
				# Sync up the dice
				client._send_dict({
					"message_type": "dice",
					"data": { "dice": $Control/Screen/Dice.dice_to_array() }
				})
				# Deselecting the previous province means redeploying risen troops
				if GameData.selectedProvID != GameData.gameAttackedProvID \
				  or GameData.gameAttackedProvID == -1:
					var sel_prov = GameData.provinces[GameData.selectedProvID]
					sel_prov.commitDeployment()
					sel_prov.sendProvToServer()
					if oldProvID != -1:
						GameData.provinces[oldProvID].commitDeployment()
						GameData.provinces[oldProvID].sendProvToServer()
				
				# Raising defenders in the new province (as many as possible)
				if GameData.gameAttackedProvID != -1 \
				  and GameData.selectedProvID != GameData.gameAttackedProvID:
					var attacked_prov = GameData.provinces[GameData.gameAttackedProvID]
					while attacked_prov._to_add < 2 and attacked_prov._soldiers > 0:
						attacked_prov.raiseTroops()
					attacked_prov.sendProvToServer()
		GameData.Phase.fortify:
			if GameData.localPlayerIndex == GameData.turnPlayerIndex:
				if GameData.selectedProvID != GameData.gameAttackedProvID \
				  and GameData.gameAttackedProvID != -1 \
				  and GameData.provinces[GameData.gameSelectedProvID]._soldiers > 1:
					var sel_prov: GameData.Province = GameData.provinces[GameData.gameSelectedProvID]
					sel_prov.updateInfo(sel_prov._owner, 1, sel_prov._soldiers - 1)
					sel_prov.sendProvToServer()
				
				# Deselect provinces
				if oldProvID != -1 and oldProvID != newProvID:
					print("DESELECTING PROVINCES")
					var sel_prov = GameData.provinces[GameData.selectedProvID]
					var mov_prov = GameData.provinces[oldProvID]
					sel_prov.updateInfo(sel_prov._owner, sel_prov._soldiers + sel_prov._to_add + mov_prov._to_add, 0)
					mov_prov.updateInfo(mov_prov._owner, mov_prov._soldiers, 0)
					sel_prov.sendProvToServer()
					mov_prov.sendProvToServer()

func _on_end_turn_clicked():
	# Make sure player is allowed to end their turn
	match GameData.gamePhase:
		GameData.Phase.init_deploy:
			if GameData.turnAvailSoldiers != 0: return
		GameData.Phase.deploy:
			if GameData.turnAvailSoldiers != 0: return
		GameData.Phase.attack:
			if GameData.localPlayerIndex == GameData.turnPlayerIndex:
				GameData.gameAttackedProvID = -1
		GameData.Phase.fortify:
			if GameData.localPlayerIndex == GameData.turnPlayerIndex:
				GameData.gameAttackedProvID = -1
		_:
			pass
	client._send_dict({"message_type": "end_turn"})
