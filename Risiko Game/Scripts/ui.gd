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
	
	print(str(GameData.gameSelectedProvID) + "ASHHHHHHHHH")
	GameData.gameSelectedProvID = 0
	
	_on_new_turn_player_index((GameData.turnPlayerIndex + 1) % GameData.players.size(), GameData.turnPlayerIndex)

func _process(_delta):
	pass

func _on_new_turn_player_index(oldTurnPlayerIndex: int, newTurnPlayerIndex: int):
	print("NEW PLAYER INDEX!")
	$Screen/Players.get_child(oldTurnPlayerIndex).setBackgroundColor(Color.BLACK)
	$Screen/Players.get_child(newTurnPlayerIndex).setBackgroundColor(Color.GREEN)

func _on_prov_clicked(_oldProvID: int, _newProvID: int):
	var selProv = GameData.get_selected_prov()
	lowerBanProvName.text = ": " + str(selProv._name)
	lowerBanProvSold.text = ": " + str(selProv._soldiers)
