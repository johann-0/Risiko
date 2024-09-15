extends CanvasLayer

func _ready() -> void:
	## Connect Signals
	$Screen/EndTurn.pressed.connect(on_end_turn_pressed)
	GameData.new_loc_sel_prov.connect(on_new_loc_sel_prov)
	GameData.new_turn.connect(on_new_turn)
	for province in GameData.provinces:
		province.infoUpdated.connect(on_prov_info_updated)
	
	## Add the players to the UI
	var index = 0
	for player in GameData.players:
		var player_ui = Player_UI.new_player_UI(Vector2i(0,index * 14), player.name, player.color)
		$Screen/Players.add_child(player_ui)
		index += 1

func on_prov_info_updated(prov_id: int) -> void:
	## Update the available troops
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.dep_avail_sols)
	## Update to_add value of the province
	if prov_id != -1:
		$Screen/LowerBanner/ToAddTroops/Value.text = ": "+str(GameData.provinces[prov_id].to_add)
	match GameData.cur_phase:
		GameData.Phase.deploy, GameData.Phase.init_deploy:
			if GameData.is_loc_players_turn():
				if GameData.dep_avail_sols == 0:
					$Screen/EndTurn.disabled = false
				else:
					$Screen/EndTurn.disabled = true
		_:
			pass
	
	#if GameData.gamePhase == GameData.Phase.attack \
	  #and GameData.gameSelectedProvID != -1:
		#update_dice() # DEBUG_DICE

func on_dice_are_rolling(oldVal: bool, newVal: bool) -> void:
	if newVal == true:
		$Screen/EndTurn.hide()
	else:
		$Screen/EndTurn.show()

func update_dice() -> void:
	if GameData.gamePhase == GameData.Phase.attack \
	  and GameData.gameAttackedProvID != -1 \
	  and GameData.provinces[GameData.gameAttackedProvID]._owner != GameData.turnPlayerIndex:
		var sel_prov = GameData.provinces[GameData.gameSelectedProvID]
		var attacked_prov = GameData.provinces[GameData.gameAttackedProvID]
		#if GameData.localPlayerIndex != GameData.turnPlayerIndex: # DEBUG
			#print("att: " + str(sel_prov._to_add) + ". def: " + str(attacked_prov._to_add))
		$Screen/Dice.show_dice(sel_prov._to_add, attacked_prov._to_add)
	else:
		$Screen/Dice.hide_dice()

func on_new_turn(oldIndex: int, newIndex: int \
  , oldPhase: GameData.Phase, newPhase: GameData.Phase) -> void: 
	if oldIndex != -1:
		$Screen/Players.get_child(oldIndex).is_not_players_turn()
	if newIndex != -1:
		$Screen/Players.get_child(newIndex).is_players_turn()
	
	$Screen/UpperBanner/TurnStat/Value.text = GameData.Phase.find_key(newPhase)
	
	if newIndex == GameData.loc_player_ind:
		$Screen/EndTurn.show()
	else:
		$Screen/EndTurn.hide()
	
	if oldPhase == newPhase:
		$Screen/UpperBanner/TurnStat/Value.text = ": " + str(GameData.Phase.keys()[newPhase])
	
	if newPhase == GameData.Phase.deploy or newPhase == GameData.Phase.init_deploy:
		$Screen/UpperBanner/AvailTroops.show()
		$Screen/UpperBanner/AvailTroopsTexture.show()
		$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.dep_avail_sols)
		if GameData.is_loc_players_turn():
			$Screen/EndTurn.disabled = true
	else:
		$Screen/UpperBanner/AvailTroops.hide()
		$Screen/UpperBanner/AvailTroopsTexture.hide()
	
	match GameData.cur_phase:
		GameData.Phase.init_deploy:
			$Screen/EndTurn.text = "End Turn"
		GameData.Phase.deploy:
			$Screen/EndTurn.text = "Next Phase"
		GameData.Phase.attack:
			$Screen/EndTurn.text = "Next Phase"
		GameData.Phase.fortify:
			$Screen/EndTurn.text = "End Turn"
		_:
			pass

func on_new_loc_sel_prov(_oldProvID: int, _newProvID: int) -> void:
	var p_name: String = ""
	var p_soldiers: String = ""
	var p_to_add: String = ""
	if GameData.loc_sel_prov != -1:
		var sel_prov: Province = GameData.provinces[GameData.loc_sel_prov]
		p_name = str(sel_prov.name)
		p_soldiers = str(sel_prov.soldiers)
		p_to_add = str(sel_prov.to_add)
	#update_dice()
	$Screen/LowerBanner/NameStat/Value.text = ": " + p_name
	$Screen/LowerBanner/SoldiersStat/Value.text = ": " + p_soldiers
	$Screen/LowerBanner/ToAddTroops/Value.text = ": " + p_to_add

func on_end_turn_pressed() -> void:
	Commander.add_command(EndTurnPressed.new([]))
