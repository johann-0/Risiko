extends Node2D

signal _prov_clicked(provID: int)

var selectedProv : int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func prov_clicked(provID: int):
	emit_signal("_prov_clicked", provID)
