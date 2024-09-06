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
	
	on_new_turn((GameData.turnPlayerIndex + 1) % GameData.players.size(), GameData.turnPlayerIndex)

func _on_prov_info_updated(provID: int):
	# Update the available troops
	$Screen/UpperBanner/AvailTroops/Value.text = ": " + str(GameData.turnAvailSoldiers)

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
