extends Node2D
@onready var curMap : Sprite2D = $WastelandMap
@onready var mat = $Map.material

signal map_prov_clicked(provID: int)


func _ready():
	mat.set_shader_parameter("base_color", Color8(100,0,0))
	mat.set_shader_parameter("num_of_provinces", 42)
	
	var extracted : Array
	for i in range(42):
		extracted.append(Color.WHITE)
	mat.set_shader_parameter("colors", extracted)
	


func _process(delta):
	pass


func set_prov_color(provID : int, color : Color):
	var extracted : Array = mat.get_shader_parameter("colors")
	extracted[provID] = color
	mat.set_shader_parameter("colors", extracted)

