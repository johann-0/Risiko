class_name Soldier_UI
extends Node2D

const COLORS: Array = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW]
var prov_id: int = -1
var color_id: int = 0:
	set(new_id):
		if new_id < 0 or new_id > len(COLORS):
			color_id = 0
		else:
			color_id = new_id
		# Adjust the sprite window
		$Sprite.frame = 2 * new_id;
		#$Sprite.get_rect().wi #idk what i was gonna write here
var facing_right: bool = false:
	set(newfacing_right):
		if facing_right == true && newfacing_right == false:
			$Sprite.frame -=1
		elif facing_right == false && newfacing_right == true:
			$Sprite.frame += 1
		facing_right = newfacing_right
var soldiers: int = 0:
	set(newSoldiers):
		soldiers = newSoldiers
		$Strength.text = str(soldiers)
		checkIfEmpty()
var toAdd: int = 0:
	set(newAdd):
		toAdd = newAdd
		$ToAdd.text = str(toAdd)
		checkIfEmpty()

func checkIfEmpty():
	if toAdd == 0 and soldiers == 0:
		hide()
	else:
		show()
		if toAdd == 0:
			$ToAdd.hide()
		else:
			$ToAdd.show()

func updateInfo(_provID: int):
	var newOwner = GameData.provinces[prov_id]._owner
	if newOwner == -1:
		color_id = 0
		soldiers = 0
		toAdd = 0
	else:
		color_id = GameData.players[GameData.provinces[prov_id]._owner].getColorID()
		soldiers = GameData.provinces[prov_id]._soldiers
		toAdd = GameData.provinces[prov_id]._to_add

static func new_soldier(_prov_id: int, _facing_right: bool):
	var my_scene: PackedScene = load("res://Scenes/soldier.tscn")
	var toRet: Soldier_UI = my_scene.instantiate()
	toRet.facing_right = _facing_right
	toRet.prov_id = _prov_id
	GameData.provinces[_prov_id].infoUpdated.connect(toRet.updateInfo)
	toRet.position = GameData.provinces[_prov_id]._center
	
	toRet.updateInfo(_prov_id)
	
	return toRet


