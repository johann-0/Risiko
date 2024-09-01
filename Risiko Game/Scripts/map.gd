extends Node2D

@onready var curMap: Sprite2D = $WastelandMap
@onready var mat: Material = $Map.material
@onready var NUM_PROV: int = GameData.NUM_PROV
@onready var soldierObj = preload("res://Scenes/soldier.tscn")

signal map_prov_clicked(provID: int)

func _ready():
	# Connect to signal
	GameData._prov_clicked.connect(_on_prov_clicked)
	GameData.newGameSelectedProvince.connect(_on_new_map_prov)
	
	# Hide all maps except Map and curMap
	$MouseMap.hide()
	$DebugMap.hide()
	$WastelandMap.hide()
	$Map.show()
	curMap.show()
	
	# Initialise shader parameters
	mat.set_shader_parameter("base_color", Color8(100,0,0))
	mat.set_shader_parameter("num_of_provinces", NUM_PROV)
	var provColors: Array = []
	provColors.resize(NUM_PROV)
	provColors.fill(Color.TRANSPARENT)
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

func _on_new_map_prov(oldProvID: int, newProvID: int):
	if(oldProvID == newProvID):
		return
	# Color out the previous province
	if oldProvID != GameData.Province.WASTELAND_ID:
		var provIDs: Array = [oldProvID]
		var colors: Array = [Color.TRANSPARENT]
		set_prov_colors(provIDs, colors)
	
	# Color in the new province
	if newProvID != GameData.Province.WASTELAND_ID:
		var provIDs: Array = [newProvID]
		var colors: Array = [GameData.GAME_SEL_COLOR]
		set_prov_colors(provIDs, colors)

func _on_prov_clicked(oldProvID: int, newProvID: int):
	if(oldProvID == newProvID):
		return
	# Color out previous province(s)
	if oldProvID != GameData.Province.WASTELAND_ID:
		var oldProv = GameData.provinces[oldProvID]
		var provIDs: Array = []
		var colors: Array = []
		provIDs.append(oldProvID)
		provIDs.append_array(oldProv._neighbors)
		colors.resize(len(provIDs))
		colors.fill(Color.TRANSPARENT)
		set_prov_colors(provIDs, colors)
	
	# Color in new province(s)
	if newProvID != GameData.Province.WASTELAND_ID:
		var newProv = GameData.provinces[newProvID]
		var provIDs: Array = []
		var colors: Array = []
		provIDs.append(newProvID)
		provIDs.append_array(newProv._neighbors)
		colors.resize(len(provIDs))
		colors.fill(GameData.NEIGH_COLOR)
		colors[0] = GameData.SEL_COLOR
		set_prov_colors(provIDs, colors)
