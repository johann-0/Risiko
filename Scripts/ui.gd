extends CanvasLayer
@onready var lowerBanLabel : Label = $Screen/LowerBanner/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	setText()

func setText():
	var selProv = GameData.get_selected_prov()
	lowerBanLabel.text = "Selected Province: " + str(selProv._name)
	
