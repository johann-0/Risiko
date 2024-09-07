extends CanvasLayer

func _ready():
	GameData._prov_clicked.connect(_on_prov_clicked)
	GameData.diceAreRollingChanged.connect(_on_dice_are_rolling)
	for province in GameData.provinces:
		province.infoUpdated.connect(_on_prov_info_updated)
	
	# Add the players and available troops to the UI
	var index = 0
	for player in GameData.players:
		var player_ui = Player_UI.new_player_UI(Vector2i(0,index * 14), player._id, player._name, player._color)
		$Screen/Players.add_child(player_ui)
		index += 1
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)
	
	on_new_turn((GameData.turnPlayerIndex + 1) % GameData.players.size(), GameData.turnPlayerIndex)

func _on_prov_info_updated(provID: int):
	#if GameData.localPlayerIndex != GameData.turnPlayerIndex: # DEBUG
		#print("prov_updated (not my turn)")
	# Update the available troops
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)
	# Update to_add value of the province
	if GameData.selectedProvID != -1:
		$Screen/LowerBanner/ToAddTroops/Value.text = ": "+str(GameData.provinces[GameData.selectedProvID]._to_add)
	if GameData.gamePhase == GameData.Phase.attack \
	  and GameData.gameSelectedProvID != -1:
		update_dice()

func _on_dice_are_rolling(oldVal: bool, newVal: bool):
	if newVal == true:
		$Screen/EndTurn.hide()
	else:
		$Screen/EndTurn.show()

func update_dice():
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

# Called by parent
func on_new_turn(oldIndex, newIndex, indexChanged = false \
  , oldPhase = GameData.Phase.lobby, newPhase = GameData.Phase.lobby, phaseChanged = false): 
	if oldIndex != -1:
		$Screen/Players.get_child(oldIndex).setBackgroundColor(Color.BLACK)
	if newIndex != -1:
		$Screen/Players.get_child(newIndex).setBackgroundColor(Color.GREEN)
	
	if newIndex == GameData.localPlayerIndex:
		$Screen/EndTurn.show()
	else:
		$Screen/EndTurn.hide()
	
	if phaseChanged:
		$Screen/UpperBanner/TurnStat/Value.text = ": " + str(GameData.Phase.keys()[newPhase])
	
	if GameData.gamePhase == GameData.Phase.deploy or GameData.gamePhase == GameData.Phase.init_deploy:
		$Screen/UpperBanner/AvailTroops.show()
		$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)
	else:
		$Screen/UpperBanner/AvailTroops.hide()

func _on_prov_clicked(_oldProvID: int, _newProvID: int):
	var selProv: GameData.Province = GameData.get_selected_prov()
	var provName: String = ""
	var provSoldiers: String = ""
	var provToAdd: String = ""
	if selProv._id != -1:
		provName = str(selProv._name)
		provSoldiers = str(selProv._soldiers)
		provToAdd = str(selProv._to_add)
	#update_dice()
	$Screen/LowerBanner/NameStat/Value.text = ": " + provName
	$Screen/LowerBanner/SoldiersStat/Value.text = ": " + provSoldiers
	$Screen/LowerBanner/ToAddTroops/Value.text = ": " + provToAdd
