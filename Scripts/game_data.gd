extends Node2D

signal _prov_clicked(provID: int)

var selectedProv: int = -1
var NUM_PROV: int
var provinces: Array

enum Phase { DEPLOY, ATTACK, FORTIFY}
var curPhase : Phase = Phase.DEPLOY

class Province:
	var _id: int
	var _name: String
	var _neighbors: Array
	
	static func wasteland():
		var wasteland = Province.new()
		wasteland._id = -1
		wasteland._name = "wasteland"
		wasteland._neighbors = []
		return wasteland

func _ready():
	add_provinces_to_arr()


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
		newProv._id = provinceID
		newProv._name = json.data.provinces[provinceID]
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
	if selectedProv == -1:
		return Province.wasteland()
	return provinces[selectedProv]
