extends CanvasLayer
@onready var lowerBanProvName : Label = $Screen/LowerBanner/NameStat/Value
@onready var lowerBanProvSold : Label = $Screen/LowerBanner/SoldiersStat/Value

func _ready():
	GameData.connect("_prov_clicked", Callable(self, "_on_prov_clicked"))


func _process(delta):
	setText()


func setText():
	var selProv = GameData.get_selected_prov()
	lowerBanProvName.text = ": " + str(selProv._name)
	lowerBanProvSold.text = ": " + str(selProv._soldiers)
