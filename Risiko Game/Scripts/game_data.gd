extends Node2D

signal _prov_clicked(oldProvID: int, newProvID: int)
signal newTurnPlayerIndex(oldIndex: int, newIndex: int)
signal newPhase(oldPhase: Phase, newPhase: Phase)
signal newGameSelectedProvince(oldProvID: int, newProvID: int)

const SEL_COLOR: Color = Color8(0, 0, 0, 100)
const NEIGH_COLOR: Color = Color8(0, 0, 0, 50)
const GAME_SEL_COLOR: Color = Color8(255, 0, 0, 255)

var NUM_PROV: int = 0
var provinces: Array = []
var players: Array = []

var gameSelectedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = gameSelectedProvID
		gameSelectedProvID = newProvID
		newGameSelectedProvince.emit(oldProvID, newProvID)
var selectedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = selectedProvID
		selectedProvID = newProvID
		_prov_clicked.emit(oldProvID, newProvID)
var turnPlayerIndex: int = -1:
	set(newIndex):
		var oldIndex = turnPlayerIndex
		turnPlayerIndex = newIndex
		newTurnPlayerIndex.emit(oldIndex, newIndex)
var gamePhase: Phase = Phase.DEPLOY
var localPlayerIndex: int = 0

const Client = preload("res://Scripts/WS_client.gd")
@onready var client: Client

func client_connected():
	pass
func client_disconnected():
	pass
func client_rec_data(_data: String):
	pass
func client_connecting():
	pass

class ServerName:
	var _address: String
	var _port: int
	func _init(address: String, port: int):
		_address = address
		_port = port
	func getName():
		return _address + ":" + str(_port)
	static func DEFAULT_SERVER_NAME():
		return ServerName.new("127.0.0.1", 8080)

var serverName: ServerName = ServerName.DEFAULT_SERVER_NAME()

enum Phase { DEPLOY, ATTACK, FORTIFY}

class Player:
	var _id: int
	var _name: String
	var _color: Color
	var _soldiers: int
	func _init(id: int, name: String, color: Color = Color.AZURE, soldiers: int = 0):
		_id = id
		_name = name
		_color = color
		_soldiers = soldiers
	static func DEFAULT_PLAYER():
		return Player.new(0, "Player_" + str(randi()%64))
	func equals(otherPlayer: Player):
		return _id == otherPlayer._id
	func _to_string():
		return JSON.stringify(_to_JSON())
	func _to_JSON():
		return { "id": _id, "name": _name, "color": _color.to_html(), "soldiers": _soldiers }

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
	players.append(Player.DEFAULT_PLAYER())
	add_provinces_to_arr()
	
	provinces[0]._soldiers = 69
	
	client = Client.new()
	client.connected.connect(client_connected)
	client.disconnected.connect(client_disconnected)
	client.received_data.connect(client_rec_data)
	client.connecting.connect(client_connecting)
	add_child(client)


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
	var _id_sort = func (p1: Province, p2: Province):
		if p1._id < p2._id:
			return true
		return false
	provinces.sort_custom(_id_sort)


func id_sort(p1: Province, p2: Province):
	if p1._id < p2._id:
		return true
	return false


func get_selected_prov():
	if selectedProvID == Province.WASTELAND_ID:
		return Province.WASTELAND()
	return provinces[selectedProvID]


func players_to_JSON():
	var toReturn = []
	for player in players:
		toReturn.append(player._to_JSON())
	return toReturn


func players_to_string():
	return JSON.stringify(players_to_JSON())
