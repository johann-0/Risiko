extends CanvasLayer

@onready var lowerBanProvName : Label = $Screen/LowerBanner/NameStat/Value
@onready var lowerBanProvSold : Label = $Screen/LowerBanner/SoldiersStat/Value

func _ready():
	GameData._prov_clicked.connect(_on_prov_clicked)
	for province in GameData.provinces:
		province.infoUpdated.connect(_on_prov_info_updated)
	
	# Add the players and available troops to the UI
	var index = 0
	for player in GameData.players:
		var player_ui = Player_UI.new_player_UI(Vector2i(0,index * 14), player._id, player._name, player._color)
		$Screen/Players.add_child(player_ui)
		index += 1
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)
	
	newTurn((GameData.turnPlayerIndex + 1) % GameData.players.size(), GameData.turnPlayerIndex)

func _on_prov_info_updated(provID: int):
	# Update the available troops
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)

func newTurn(oldTurnPlayerIndex: int, newTurnPlayerIndex: int):
	if oldTurnPlayerIndex != -1:
		$Screen/Players.get_child(oldTurnPlayerIndex).setBackgroundColor(Color.BLACK)
	if newTurnPlayerIndex != -1:
		$Screen/Players.get_child(newTurnPlayerIndex).setBackgroundColor(Color.GREEN)
	
	if newTurnPlayerIndex == GameData.localPlayerIndex:
		$Screen/EndTurn.show()
	else:
		$Screen/EndTurn.hide()
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)

func _on_prov_clicked(_oldProvID: int, _newProvID: int):
	var selProv = GameData.get_selected_prov()
	var provName: String = ""
	var provSoldiers: String = ""
	if selProv._id != -1:
		provName = str(selProv._name)
		provSoldiers = str(selProv._soldiers)
	lowerBanProvName.text = ": " + provName
	lowerBanProvSold.text = ": " + provSoldiers
