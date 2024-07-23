extends Node2D


func _ready():
	GameData.connect("_prov_clicked", Callable(self, "_on_prov_clicked"))


func set_prov_color(provID : int, color : Color):
	$LeftMap.set_prov_color(provID, color)
	$RightMap.set_prov_color(provID, color)


func _on_prov_clicked(provinceID):
	if(GameData.selectedProv == provinceID):
		return
	# Unselect prev. province
	set_prov_color(GameData.selectedProv, Color.TRANSPARENT)
	GameData.selectedProv = provinceID
	if GameData.selectedProv != -1:
		set_prov_color(GameData.selectedProv, Color.GREEN)
