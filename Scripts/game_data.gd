extends Node2D

signal _prov_clicked(provID: int)
const SEL_COLOR: Color = Color8(0, 255, 0, 255)
const NEIGH_COLOR: Color = Color8(0, 255, 0, 70)

var NUM_PROV: int = 0
var provinces: Array = []
var players: Array = []

var selectedProvID: int = Province.WASTELAND_ID
var turnPlayerID: int = -1
var gamePhase: Phase = Phase.DEPLOY
var localPlayerIndex: int = 0
var serverName: String = ""

enum Phase { DEPLOY, ATTACK, FORTIFY}

class Player:
	var _id: int
	var _name: String
	var _color: Color
	func _init(id: int, name: String, color: Color = Color.AZURE):
		_id = id
		_name = name
		_color = color
	static func PLACEHOLDER():
		var placeholder = Player.new(0, "Placeholder Local Man")
		return placeholder
	func equals(otherPlayer: Player):
		return _id == otherPlayer._id

class Province:
	var _id: int
	var _name: String
	var _neighbors: Array
	var _soldiers: int
	var _center: Vector2
	static var WASTELAND_ID: int = -1
	func _init(id: int, name: String, neighbors: Array, soldiers: int, center: Vector2):
		_id = id
		_name = name
		_neighbors = neighbors
		_soldiers = soldiers
		_center = center 
	static func WASTELAND():
		var wasteland = Province.new(WASTELAND_ID, "Wasteland", [], 0, Vector2(0,0))
		return wasteland


func _ready():
	players.append(Player.PLACEHOLDER())
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
		var extrProv = json.data.provinces[provinceID]
		var centerArr = extrProv["center"]
		var newProv = Province.new(int(provinceID), extrProv["name"], extrProv["neighbors"], 0, Vector2(centerArr[0], centerArr[1]))
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
	if selectedProvID == Province.WASTELAND_ID:
		return Province.WASTELAND()
	return provinces[selectedProvID]


func set_selected_prov(newID : int):
	selectedProvID = newID
