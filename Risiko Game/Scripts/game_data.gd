extends Node2D
var DEBUG_MODE: bool = false

signal _prov_clicked(oldProvID: int, newProvID: int)
signal newTurn(oldIndex: int, newIndex: int, indexChanged: bool, \
			   oldPhase: Phase, newPhase: Phase, phaseChanged: bool)
signal newGameSelectedProvince(oldProvID: int, newProvID: int)
signal newGameAttackedProvince(oldProvID: int, newProvID: int)
signal soldierDeployed(provID: int)
signal randomDeploymentChanged()
signal diceAreRollingChanged(oldVal: bool, newVal: bool)

const SEL_COLOR: Color = Color8(0, 255, 0, 100)
const NEIGH_COLOR: Color = Color8(0, 255, 0, 50)
const GAME_SEL_COLOR: Color = Color8(255, 0, 0, 100)
const GAME_ATT_COLOR: Color = Color8(0, 0, 255, 100)

var NUM_PROV: int = 0
var provinces: Array[Province] = []
var players: Array[Player] = []
var already_moved: bool = false
var randomDeployment = false:
	set(newVal):
		randomDeployment = newVal
		randomDeploymentChanged.emit()
var diceAreRolling: bool = false:
	set(newVal):
		var oldVal = diceAreRolling
		diceAreRolling = newVal
		if oldVal != newVal:
			diceAreRollingChanged.emit(oldVal, newVal)

var gameSelectedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = gameSelectedProvID
		gameSelectedProvID = newProvID
		newGameSelectedProvince.emit(oldProvID, newProvID)
var gameAttackedProvID: int = Province.WASTELAND_ID:
	set(newProvID):
		var oldProvID = gameAttackedProvID
		gameAttackedProvID = newProvID
		var sel_prov = get_selected_prov()
		#if sel_prov != Province.WASTELAND_ID: # DEBUG
			#sel_prov._soldiers = provinces[oldProvID]._to_add
			#sel_prov._to_add = 0
		newGameAttackedProvince.emit(oldProvID, newProvID)
		if localPlayerIndex == turnPlayerIndex:
			client._send_dict({
				"message_type": "attack_prov_selected",
				"data": {"oldProvID": oldProvID, "newProvID": newProvID},
				})
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
	var _neighbors: Array[int]; var _center: Vector2
	var _soldiers: int; var _to_add: int = 0
	func updateInfo(pOwner: int, pSoldiers: int, pToAdd: int):
		if pOwner == -1 or (pSoldiers + pToAdd) == 0: # If province is empty
			_owner = -1
			_soldiers = 0
			_to_add = 0
		else:
			_owner = pOwner; _soldiers = pSoldiers; _to_add = pToAdd;
		infoUpdated.emit(_id)
	func sendProvToServer():
		GameData.client._send_dict({ "message_type": "prov_updated",
			"data": {"prov": _to_JSON(), "avail_soldiers": GameData.turnAvailSoldiers}})
	func addDeploy(pOwner: int = _owner):
		GameData.turnAvailSoldiers -= 1
		updateInfo(pOwner, _soldiers, _to_add + 1)
		sendProvToServer()
	func removeDeploy(pOwner: int = _owner):
		GameData.turnAvailSoldiers += 1
		updateInfo(pOwner, _soldiers, _to_add - 1)
		sendProvToServer()
	func raiseTroops():
		updateInfo(_owner, _soldiers - 1, _to_add + 1)
		sendProvToServer()
	func lowerTroops():
		updateInfo(_owner, _soldiers + 1, _to_add - 1)
		sendProvToServer()
	func destroyTroops(toDestroy: int):
		updateInfo(_owner, _soldiers, _to_add - toDestroy)
		sendProvToServer()
	func commitDeployment():
		if _to_add == 0: return
		updateInfo(_owner, _soldiers + _to_add, 0)
	func invade(defProvID: int, goTo: bool):
		var def_prov = GameData.provinces[defProvID]
		if goTo == true:
			if _to_add > 0:
				updateInfo(_owner, _soldiers, _to_add - 1)
			else:
				updateInfo(_owner, _soldiers - 1, _to_add)
			sendProvToServer()
			def_prov.updateInfo(_owner, def_prov._soldiers, def_prov._to_add + 1)
			def_prov.sendProvToServer()
		else:
			if def_prov._to_add > 1:
				def_prov.updateInfo(_owner, def_prov._soldiers, def_prov._to_add - 1)
				def_prov.sendProvToServer()
				updateInfo(_owner, _soldiers, _to_add + 1)
				sendProvToServer()
	
	func _init(id: int, name: String, neighbors: Array[int], soldiers: int, center: Vector2, owner: int = -1):
		_id=id; _name=name; _neighbors=neighbors; _soldiers=soldiers; _center=center; _owner=owner;
	func _to_JSON(): return {"id":_id, "name":_name, "owner":_owner, "soldiers":_soldiers, "to_add":_to_add};
	func _to_string(): return JSON.stringify(_to_JSON());
	
	static var WASTELAND_ID: int = -1;
	static func WASTELAND(): return Province.new(WASTELAND_ID, "Wasteland", [], 0, Vector2(0,0));

func _ready():
	players.append(Player.DEFAULT_PLAYER())
	get_provinces_from_json()
	client = Client.new()
	add_child(client)

func are_provs_reachable(from_id: int, to_id: int):
	var from_owner: int = provinces[from_id]._owner
	var re_arr: Array[bool] = [] # holds info on reached provinces
	re_arr.resize(NUM_PROV)
	re_arr.fill(false)
	re_arr[from_id] = true
	var queue: Array[int] = [from_id]
	while not queue.is_empty():
		var cur_prov = queue.pop_front()
		if cur_prov == to_id:
			return true
		for neighbor_id in provinces[cur_prov]._neighbors:
			if provinces[neighbor_id]._owner != from_owner:
				continue
			if re_arr[neighbor_id] == false:
				re_arr[neighbor_id] = true
				queue.append(neighbor_id)

func setNewTurn(newIndex: int, newPhase: Phase):
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
		var neighbors: Array[int] = []
		for neighbor in extrProv["neighbors"]:
			neighbors.append(int(neighbor))
		var newProv = Province.new(int(provinceID), extrProv["name"], neighbors, 0, Vector2(centerArr[0], centerArr[1]))
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
