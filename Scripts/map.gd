extends Node2D

@onready var curMap: Sprite2D = $WastelandMap
@onready var mat: Material = $Map.material
@onready var NUM_PROV: int = GameData.NUM_PROV

signal map_prov_clicked(provID: int)


func _ready():
	# Hide all maps except Map and curMap
	$MouseMap.hide()
	$DebugMap.hide()
	$WastelandMap.hide()
	$Map.show()
	curMap.show()
	
	# Initialise shader parameters
	mat.set_shader_parameter("base_color", Color8(100,0,0))
	mat.set_shader_parameter("num_of_provinces", NUM_PROV)
	var provColors: Array
	for i in range(NUM_PROV):
		provColors.append(Color.TRANSPARENT)
	mat.set_shader_parameter("colors", provColors)


func set_prov_color(provID: int, color: Color):
	var extracted: Array = mat.get_shader_parameter("colors")
	extracted[provID] = color
	mat.set_shader_parameter("colors", extracted)

