extends Node2D

@onready var curMap: Sprite2D = $WastelandMap
@onready var mat: Material = $Map.material
@onready var NUM_PROV: int = GameData.NUM_PROV
@onready var soldierObj = preload("res://Scenes/soldier.tscn")

signal map_prov_clicked(provID: int)


func _ready():
	# Connect to signal
	GameData.connect("_prov_clicked", Callable(self, "_on_prov_clicked"))
	
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
	
	# Load stuff onto provinces
	for prov in GameData.provinces:
		if prov._center == Vector2(-1,-1):
			continue
		# Draw numbers at the centers
		var newSold = soldierObj.instantiate()
		newSold.soldiers = prov._soldiers
		newSold.visibility_layer = 1
		# Center the label
		newSold.position = prov._center
		var spriteSize: Vector2 = newSold.get_child(0).get_rect().size
		newSold.position -= Vector2(spriteSize.x/2, spriteSize.y/2)
		$SoldierObjs.add_child(newSold)


func _process(_delta):
	var colors: Array = mat.get_shader_parameter("colors")
	for neighbors in GameData.get_selected_prov()._neighbors:
		pass
	mat.set_shader_parameter("colors", colors)


func set_prov_colors(provIDs: Array, colors: Array):
	var extracted: Array = mat.get_shader_parameter("colors")
	for i in range(len(provIDs)):
		extracted[provIDs[i]] = colors[i]
	mat.set_shader_parameter("colors", extracted)


func set_prov_color(provID: int, color: Color):
	var extracted: Array = mat.get_shader_parameter("colors")
	extracted[provID] = color
	mat.set_shader_parameter("colors", extracted)

func _on_prov_clicked(newProvID: int):
	var oldProvID = GameData.get_selected_prov()._id
	if(oldProvID == newProvID):
		return
	# Color out previous province(s)
	if oldProvID != GameData.Province.WASTELAND_ID:
		var curProv = GameData.provinces[oldProvID]
		var provIDs: Array = [oldProvID]
		var colors: Array = []
		provIDs.append_array(curProv._neighbors)
		colors.resize(len(provIDs))
		colors.fill(Color.TRANSPARENT)
		set_prov_colors(provIDs, colors)
	
	# Color in new province(s)
	GameData.set_selected_prov(newProvID)
	if newProvID != GameData.Province.WASTELAND_ID:
		var curProv = GameData.provinces[newProvID]
		var provIDs: Array = [newProvID]
		var colors: Array = []
		provIDs.append_array(curProv._neighbors)
		colors.resize(len(provIDs))
		colors.fill(GameData.NEIGH_COLOR)
		colors[0] = GameData.SEL_COLOR
		set_prov_colors(provIDs, colors)
