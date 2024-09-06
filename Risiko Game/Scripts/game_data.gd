extends Node2D

signal _prov_clicked(oldProvID: int, newProvID: int)
signal newTurn(oldIndex: int, newIndex: int, indexChanged: bool, \
			   oldPhase: Phase, newPhase: Phase, phaseChanged: bool)
signal newGameSelectedProvince(oldProvID: int, newProvID: int)
signal soldierDeployed(provID: int)
signal randomDeploymentChanged()

const SEL_COLOR: Color = Color8(0, 255, 0, 100)
const NEIGH_COLOR: Color = Color8(0, 255, 0, 50)
const GAME_SEL_COLOR: Color = Color8(255, 0, 0, 100)

var NUM_PROV: int = 0
var provinces: Array = []
var players: Array = []
var randomDeployment = false:
	set(newVal):
		randomDeployment = newVal
		randomDeploymentChanged.emit()

var gameSelectedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = gameSelectedProvID
		gameSelectedProvID = newProvID
		newGameSelectedProvince.emit(oldProvID, newProvID)
var gameAttackedProvID: int = Province.WASTELAND_ID
var selectedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = selectedProvID
		selectedProvID = newProvID
		_prov_clicked.emit(oldProvID, newProvID)
		if localPlayerIndex == turnPlayerIndex:
			client._send_dict({
				"message_type": "prov_selected",
				"data": { "oldProvID": oldProvID, "newProvID": newProvID},
				})
var turnPlayerIndex: int = -1
var gamePhase: Phase = Phase.lobby
var localPlayerIndex: int = 0
var turnAvailSoldiers: int = 0:
	set(newVal):
		turnAvailSoldiers = newVal

const Client = preload("res://Scripts/WS_client.gd")
@onready var client: Client

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

enum Phase { lobby, init_deploy, deploy, attack, fortify}

class Player:
	var _id: int
	var _name: String
	var _color: Color
	func _init(id: int, name: String, color: Color = Color.AZURE):
		_id = id; _name = name; _color = color;
	static func DEFAULT_PLAYER():
		return Player.new(0, "Player_" + str(randi()%64))
	func equals(otherPlayer: Player):
		return _id == otherPlayer._id
	func getColorID():
		match _color:
			Color.BLUE:   return 0
			Color.RED:    return 1
			Color.GREEN:  return 2
			Color.YELLOW: return 3
			_:            return -1
	func _to_string():
		return JSON.stringify(_to_JSON())
	func _to_JSON():
		return { "id": _id, "name": _name, "color": _color.to_html() }

class Province:
	signal infoUpdated(provID: int)
	var _id: int; var _name: String; var _owner: int
	var _neighbors: Array; var _center: Vector2
	var _soldiers: int;	var _to_add: int = 0
	func updateInfo(pOwner: int, pSoldiers: int, pToAdd: int):
		if pOwner == -1 or (pSoldiers + pToAdd) == 0: # If province is empty
			_owner = -1
			_soldiers = 0
			_to_add = 0
		else:
			_owner = pOwner
			_soldiers = pSoldiers
			_to_add = pToAdd
		infoUpdated.emit(_id)
	func addDeploy(pOwner: int):
		GameData.turnAvailSoldiers -= 1
		updateInfo(pOwner, _soldiers, _to_add + 1)
		GameData.client._send_dict({
			"message_type": "prov_updated",
			"data": {"prov": _to_JSON(), "avail_soldiers": GameData.turnAvailSoldiers}})
	func removeDeploy(pOwner: int):
		GameData.turnAvailSoldiers += 1
		updateInfo(pOwner, _soldiers, _to_add - 1)
		GameData.client._send_dict({
			"message_type": "prov_updated",
			"data": {"prov": _to_JSON(), "avail_soldiers": GameData.turnAvailSoldiers}})
	func commitDeployment():
		if _to_add == 0: return
		updateInfo(_owner, _soldiers + _to_add, 0)
	func _init(id: int, name: String, neighbors: Array, soldiers: int, center: Vector2, owner: int = -1):
		_id = id; _name = name; _neighbors = neighbors; _soldiers = soldiers
		_center = center; _owner = owner
	func _to_JSON():
		return {"id": _id, "name": _name, "owner": _owner, "soldiers": _soldiers, "to_add": _to_add}
	func _to_string():
		return JSON.stringify(_to_JSON())
	static var WASTELAND_ID: int = -1
	static func WASTELAND():
		return Province.new(WASTELAND_ID, "Wasteland", [], 0, Vector2(0,0))

func _ready():
	players.append(Player.DEFAULT_PLAYER())
	get_provinces_from_json()
	client = Client.new()
	add_child(client)

func setNewTurn(newIndex: int, newPhase: Phase):
	#if newIndex != turnPlayerIndex or newPhase != gamePhase:
		var oldIndex = turnPlayerIndex
		var oldPhase = gamePhase
		var phaseChanged = false
		var indexChanged = false
		turnPlayerIndex = newIndex
		gamePhase = newPhase
		if newIndex != oldIndex:
			indexChanged = true
			print("NEW PLAYER'S TURN! " + str(oldIndex) + "->" + str(newIndex))
		if newPhase != oldPhase:
			phaseChanged = true
			print("NEW PHASE! " + str(oldPhase) + "->" + str(newPhase))
		newTurn.emit(oldIndex, newIndex, indexChanged, oldPhase, newPhase, phaseChanged)

func get_provinces_from_json():
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
	
	# Sort the array by province id
	var id_sort = func (p1: Province, p2: Province):
		if p1._id < p2._id:
			return true
		return false
	provinces.sort_custom(id_sort)

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
