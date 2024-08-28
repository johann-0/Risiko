extends Node2D

var client: GameData.Client = GameData.client

func _ready():
	GameData.connect("_prov_clicked", _on_prov_clicked)

func _on_prov_clicked(newProvID: int):
	pass
