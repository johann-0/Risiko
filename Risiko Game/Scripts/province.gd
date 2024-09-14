class_name Province

signal infoUpdated(provID: int)
signal remote_info_updated(prov_id: int)

var id: int
var name: String
var neighbors: Array
var center: Vector2

var owner: int#:
	#set(newVal):
		#owner = newVal; infoUpdated.emit(id)
var soldiers: int#:
	#set(newVal):
		#owner = newVal; infoUpdated.emit(id);
var to_add: int#:
	#set(newVal):
		#owner = newVal; infoUpdated.emit(id)

func check_if_empty() -> void:
	if soldiers + to_add == 0:
		owner = -1

func emit_updated() -> void:
	infoUpdated.emit(id)

func remote_emit_updated() -> void:
	remote_info_updated.emit(id)

func _init(_id: int, _name: String, _neighbors: Array, _soldiers: int, _center: Vector2, _owner: int = -1):
	id=_id; name=_name; neighbors=_neighbors; soldiers=_soldiers; center=_center; owner=_owner;

func _to_JSON() -> Dictionary: 
	return {"id":id, "name":name, "owner":owner, "soldiers":soldiers, "to_add":to_add};

func _to_string() -> String: return JSON.stringify(_to_JSON());

static var WASTELAND_ID: int = -1;

static func WASTELAND() -> Province: return Province.new(WASTELAND_ID, "Wasteland", [], 0, Vector2(0,0));
