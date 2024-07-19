extends Sprite2D

var provinces : Array
var NUM_PROV = 42

signal mouse_prov_clicked(provID: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_provinces_to_arr()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handleMouse()


func handleMouse():
	var mouseX = get_global_mouse_position().x - global_position.x
	var mouseY = get_global_mouse_position().y - global_position.y
	
	if !Input.is_action_just_pressed("click_left") \
		or mouseX >= texture.get_width() or mouseX < 0 \
		or mouseY >= texture.get_height() or mouseY < 0:
		return
	
	#if is_pixel_opaque(Vector2(mouseX,mouseY)):
	#	return
	
	var color = texture.get_image().get_pixel(mouseX, mouseY)
	var id = color.r8 - 100
	
	if id < 0 or id >= NUM_PROV:
		GameData.prov_clicked(-1)
		return
	
	print("id: " + str(id))
	print(str(provinces[id]) + "\n")
	
	GameData.prov_clicked(id)


func add_provinces_to_arr():
	var file = FileAccess.open("res://Assets/provinces.json", FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) != OK:
		print("Unexpected Error!")
		return
	print("Parsing success!")
	
	NUM_PROV = json.data.num_of_provinces
	for provinceID in json.data.provinces:
		provinces.append(json.data.provinces[provinceID])
