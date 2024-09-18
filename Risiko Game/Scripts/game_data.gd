extends Node2D

var DEBUG_MODE: bool = false
signal new_loc_sel_prov(old_prov_id: int, new_prov_id: int)
signal new_glo_sel_prov(old_prov_id: int, new_prov_id: int)
signal new_glo_mov_prov(old_prov_id: int, new_prov_id: int)
signal end_turn(old_idx:int, new_idx:int \
  , old_phase:Phase, new_phase:Phase)
signal new_turn(old_idx:int, new_idx:int \
  , old_phase:Phase, new_phase:Phase)
signal disable_ui()
signal enable_ui()
signal start_dice()
signal stop_dice(dice: Array[int])

const DEF_SERVER_ADDR: String = "192.168.0.166:8080"
const SEL_COLOR: Color = Color8(255, 255, 255, 90)
const NEIGH_COLOR: Color = Color8(255, 255, 255, 35)
const GAME_SEL_COLOR: Color = Color8(0, 255, 0, 100)
const GAME_MOV_COLOR: Color = Color8(255, 0, 0, 100)
const COLORS: Array[Color] = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW]
var NUM_PROV: int = 0

var provinces: Array[Province] = []
var players: Array[Player] = []
func gplayers_to_JSON() -> Array:
	var toReturn: Array = []
	for player in players:
		toReturn.append(player._to_JSON())
	return toReturn
func players_from_JSON(players_as_json: Array) -> Array[Player]:
	var toReturn: Array[Player] = []
	for p_json in players_as_json:
		toReturn.append(Player._from_JSON(p_json))
	return toReturn
func players_to_string() -> String:
	return JSON.stringify(gplayers_to_JSON())

@onready var client: UDP_client
var server_addr: String = DEF_SERVER_ADDR
#var host_player_id: int = 0 # don't think this is important

var cur_phase: Phase = Phase.main_menu
var dep_avail_sols: int = 0 # for deploying phases
var fort_already_moved: bool = false
var cur_b_phase: B_Phase = B_Phase.no_battle

enum B_Phase { no_battle, in_battle, after_battle}

enum Phase { main_menu, lobby, init_deploy, deploy, attack, fortify}

var loc_sel_prov: int = Province.WASTELAND_ID
var glo_sel_prov: int = Province.WASTELAND_ID
var glo_mov_prov: int = Province.WASTELAND_ID
var loc_player_ind: int = -1 # local_player_id
var glo_player_ind: int = -1 # global_player_id
func is_loc_players_turn() -> bool:
	return loc_player_ind == glo_player_ind

func _ready() -> void:
	get_provinces_from_json()
	client = UDP_client.new()
	add_child(client)
	var p_name = "player_" + str(abs(randi() % 100))
	GameData.loc_player_ind = 0
	GameData.players.append(Player.new(0, p_name, Color.AZURE))

#@rpc("any_peer","call_local")
#func emit_end_battle(dice: Array[int]) -> void:
	#end_battle.emit(dice)

func calculate_soldiers(player_ind: int) -> int:
	var soldiers: int = 0
	#                 Continents: [na, sa, af, eu, ai, oc]
	var last_provs: Array[int]  = [ 8, 12, 18, 25, 37, 41]
	var bonuses: Array[int]     = [ 5,  2,  3,  5,  7,  2]
	var owned_provs: int = 0
	var cont_full: bool = true
	var cont_ind: int = 0
	for prov in GameData.provinces:
		if prov.owner == player_ind:
			owned_provs += 1
		else:
			cont_full = false
		if prov.id == last_provs[cont_ind]:
			if cont_full == true:
				soldiers += bonuses[cont_ind]
			cont_ind += 1
			cont_full = true
	@warning_ignore("integer_division")
	soldiers += owned_provs / 3
	return max(soldiers, 3) # min of 3 soldiers per player

# Returns an array: e.g. [1,2] means attackers lose 1 troop and def. lose 2
func calculate_battle(dice: Array[int]) -> Array[int]: 
	var att_arr: Array[int] = dice.slice(0,3)
	var def_arr: Array[int] = dice.slice(3,5)
	var sort_desc = func (val1: int, val2: int) -> bool:
		if val1 < val2:
			return false
		return true
	att_arr.sort_custom(sort_desc)
	def_arr.sort_custom(sort_desc)
	print("att_num: " + str(att_arr) + ". def_num: " + str(def_arr))
	var toReturn: Array[int] = [0,0]
	for i in range(def_arr.size()):
		if def_arr[i] == 0:
			continue
		if def_arr[i] >= att_arr[i]:
			toReturn[0] += 1
		else:
			toReturn[1] += 1
	print("result: " + str(toReturn))
	return toReturn

func are_provs_connected(prov1: int, prov2: int) -> bool:
	var prov1_owner: int = provinces[prov1].owner
	var reachable_provs: Array[bool] = [] # holds info on reached provinces
	reachable_provs.resize(NUM_PROV)
	reachable_provs.fill(false)
	reachable_provs[prov1] = true
	var queue: Array[int] = [prov1]
	while not queue.is_empty():
		var cur_prov = queue.pop_front()
		if cur_prov == prov2:
			return true
		for neighbor_id in provinces[cur_prov].neighbors:
			if provinces[neighbor_id].owner != prov1_owner:
				continue
			if reachable_provs[neighbor_id] == false:
				reachable_provs[neighbor_id] = true
				queue.append(neighbor_id)
	return false

func id_print(text: String) -> void:
	print("[" + str(multiplayer.get_unique_id()) + "] " + text)

func get_provinces_from_json() -> void:
	var file = FileAccess.open("res://Assets/provinces.json", FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		print("Parsing provs: unexpected error!")
		return
	print("Parsing provs: success!\n")
	
	NUM_PROV = json["data"]["num_of_provinces"]
	for provinceID in json["data"]["provinces"]:
		var extrProv = json["data"]["provinces"][provinceID]
		var centerArr = extrProv["center"]
		var neighbors: Array = []
		for neighbor in extrProv["neighbors"]:
			neighbors.append(int(neighbor))
		var newProv = Province.new(int(provinceID), extrProv["name"], neighbors, 0, Vector2(centerArr[0], centerArr[1]))
		provinces.append(newProv)
	
	# Sort the array by province id
	var id_sort = func (p1: Province, p2: Province) -> bool:
		if p1.id < p2.id:
			return true
		return false
	provinces.sort_custom(id_sort)
