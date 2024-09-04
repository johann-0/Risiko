extends CanvasLayer
@onready var lowerBanProvName : Label = $Screen/LowerBanner/NameStat/Value
@onready var lowerBanProvSold : Label = $Screen/LowerBanner/SoldiersStat/Value

func _ready():
	GameData._prov_clicked.connect(_on_prov_clicked)
	GameData.newTurnPlayerIndex.connect(_on_new_turn_player_index)
	# Add the players to the UI
	var index = 0
	for player in GameData.players:
		var player_ui = Player_UI.new_player_UI(Vector2i(0,index * 14), player._id, player._name, player._color)
		$Screen/Players.add_child(player_ui)
		index += 1
	
	_on_new_turn_player_index((GameData.turnPlayerIndex + 1) % GameData.players.size(), GameData.turnPlayerIndex)

func _on_new_turn_player_index(oldTurnPlayerIndex: int, newTurnPlayerIndex: int):
	print("NEW PLAYER'S TURN! " + str(oldTurnPlayerIndex) + " " + str(newTurnPlayerIndex))
	if oldTurnPlayerIndex != -1:
		$Screen/Players.get_child(oldTurnPlayerIndex).setBackgroundColor(Color.BLACK)
	if newTurnPlayerIndex != -1:
		$Screen/Players.get_child(newTurnPlayerIndex).setBackgroundColor(Color.GREEN)
	
	if newTurnPlayerIndex == GameData.localPlayerIndex:
		$Screen/EndTurn.show()
	else:
		$Screen/EndTurn.hide()

func _on_prov_clicked(_oldProvID: int, _newProvID: int):
	var selProv = GameData.get_selected_prov()
	var provName: String = ""
	var provSoldiers: String = ""
	if selProv._id != -1:
		provName = str(selProv._name)
		provSoldiers = str(selProv._soldiers)
	lowerBanProvName.text = ": " + provName
	lowerBanProvSold.text = ": " + provSoldiers
	
