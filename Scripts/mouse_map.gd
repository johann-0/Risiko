extends Sprite2D

@onready var provinces = GameData.provinces
@onready var NUM_PROV = GameData.NUM_PROV


func _ready():
	pass


func _process(delta):
	handleMouse()


func handleMouse():
	var mouseX = get_global_mouse_position().x - global_position.x
	var mouseY = get_global_mouse_position().y - global_position.y
	
	if !Input.is_action_just_pressed("click_left") \
		or mouseX >= texture.get_width() or mouseX < 0 \
		or mouseY >= texture.get_height() or mouseY < 0:
		return
	
	var color = texture.get_image().get_pixel(mouseX, mouseY)
	var id = color.r8 - 100
	
	if id < 0 or id >= NUM_PROV or color.g != 0 or color.b != 0:
		GameData.prov_clicked(-1)
		return
	
	print("{ id: " + str(id) + ", " + str(provinces[id]._name) + " }\n")
	
	GameData.prov_clicked(id)


