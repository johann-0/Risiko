extends Node2D

signal _prov_clicked(provID: int)
const SEL_COLOR: Color = Color8(0, 255, 0, 255)
const NEIGH_COLOR: Color = Color8(0, 255, 0, 70)
const WASTELAND_ID: int = -1

var NUM_PROV: int = 0
var provinces: Array = []
var players: Array

var selectedProvID: int = WASTELAND_ID
var turnPlayerID: int = -1
var gamePhase: Phase = Phase.DEPLOY
var localPlayerID: int = 0

enum Phase { DEPLOY, ATTACK, FORTIFY}

class Player:
	var _id: int
	var _color: Color

class Province:
	var _id: int
	var _name: String
	var _neighbors: Array
	var _soldiers: int
	var _center: Vector2
	
	static func wasteland():
		var wasteland = Province.new()
		wasteland._id = WASTELAND_ID
		wasteland._name = "Wasteland"
		wasteland._neighbors = []
		return wasteland


func _ready():
	var newPlayer = Player.new()
	newPlayer._color = Color.BLUE
	newPlayer._id = 0
	players.append(newPlayer)
	add_provinces_to_arr()
	provinces[0]._soldiers = 69


func add_provinces_to_arr():
	var file = FileAccess.open("res://Assets/provinces.json", FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		print("Parsing provs: unexpected error!")
		return
	print("Parsing provs: success!")
	
	NUM_PROV = json.data.num_of_provinces
	for provinceID in json.data.provinces:
		var newProv = Province.new()
		newProv._id = int(provinceID)
		var extractedProv = json.data.provinces[provinceID]
		newProv._name = extractedProv["name"]
		newProv._neighbors = extractedProv["neighbors"]
		var centerArr = extractedProv["center"]
		newProv._center = Vector2(centerArr[0], centerArr[1])
		provinces.append(newProv)
		#print(newProv._name)
		#print(newProv._id)
	
	# Sort the array by province id
	provinces.sort_custom(id_sort)


func id_sort(p1: Province, p2: Province):
	if p1._id < p2._id:
		return true
	return false


func prov_clicked(provID: int):
	emit_signal("_prov_clicked", provID)


func get_selected_prov():
	if selectedProvID == WASTELAND_ID:
		return Province.wasteland()
	return provinces[selectedProvID]


func set_selected_prov(newID : int):
	selectedProvID = newID
