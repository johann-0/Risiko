class_name Player

var id: int
var name: String
var color: Color

func _init(_id: int, _name: String, _color: Color):
	id = _id; name = _name; color = _color;

static func DEFAULT_PLAYER() -> Player:
	return Player.new(0, "Player_" + str(randi()%64), Color.AZURE)

func equals(otherPlayer: Player) -> bool:
	return id == otherPlayer.id

func getColorID() -> int:
	match color:
		Color.BLUE:   return 0
		Color.RED:    return 1
		Color.GREEN:  return 2
		Color.YELLOW: return 3
		_:            return -1

func _to_string() -> String:
	return JSON.stringify(_to_JSON())

func _to_JSON() -> Dictionary:
	return { "id": id, "name": name, "color": color.to_html() }

static func _from_JSON(p_json: Dictionary) -> Player:
	return Player.new(p_json["id"], p_json["name"], p_json["color"])
