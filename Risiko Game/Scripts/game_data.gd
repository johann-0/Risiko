extends Node2D

var DEBUG_MODE: bool = false
signal new_loc_sel_prov(old_prov_id: int, new_prov_id: int)
signal new_glo_sel_prov(old_prov_id: int, new_prov_id: int)
signal new_glo_att_prov(old_prov_id: int, new_prov_id: int)
signal new_turn(old_idx:int, new_idx:int, idx_chgd:bool \
  , old_phase:Phase, new_phase:Phase, phase_changed:bool)
signal new_phase(old_phase: Phase, new_phase: Phase, phase_changed: bool)

const DEF_SERVER_ADDR: String = "192.168.0.166:8080"
const SEL_COLOR: Color = Color8(255, 255, 255, 100)
const NEIGH_COLOR: Color = Color8(255, 255, 255, 50)
const GAME_SEL_COLOR: Color = Color8(0, 255, 0, 100)
const GAME_ATT_COLOR: Color = Color8(255, 0, 0, 100)
const COLORS: Array = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW]
var NUM_PROV: int = 0

var provinces: Array[Province] = []
var players: Array[Player] = []
func gplayers_to_JSON() -> Array:
	var toReturn = []
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
var host_player_id: int = 0

var cur_phase: Phase = Phase.main_menu

enum Phase { main_menu, lobby, init_deploy, deploy, attack, fortify}

var loc_sel_prov: int = Province.WASTELAND_ID # local_selected_province_id
var glo_sel_prov: int = Province.WASTELAND_ID # global_selected_province_id
var glo_mov_prov: int = Province.WASTELAND_ID # global_move_to_province_id
var loc_player_id: int = -1 # local_player_id
var glo_player_id: int = -1 # global_player_id
func is_loc_players_turn() -> bool:
	return loc_player_id == glo_player_id

func _ready():
	get_provinces_from_json()
	client = UDP_client.new()
	add_child(client)
	var p_name = "player_" + str(abs(randi() % 100))
	GameData.loc_player_id = 0
	GameData.players.append(Player.new(0, p_name, Color.AZURE))

func get_provinces_from_json() -> void:
	var file = FileAccess.open("res://Assets/provinces.json", FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		print("Parsing provs: unexpected error!")
		return
	print("Parsing provs: success!")
	
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
