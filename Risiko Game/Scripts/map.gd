extends Node2D

@onready var curMap: Sprite2D = $WastelandMap
@onready var matLocal: Material = $MapLocal.material # For the province locally selected by the player
@onready var matGlobal: Material = $MapGlobal.material # For the province selected in the game
@onready var matPolitical: Material = $MapPolitical.material # For the colors of the players
@onready var NUM_PROV: int = GameData.NUM_PROV

signal map_prov_clicked(provID: int)

func setActivated(toSet: bool):
	$MouseMap.activated = toSet

func _ready():
	# Connect to signals
	GameData._prov_clicked.connect(_on_prov_clicked)
	GameData.newGameSelectedProvince.connect(_on_new_map_prov)
	for province in GameData.provinces:
		province.infoUpdated.connect(_on_info_updated)
	
	# Hide all maps except Map and curMap
	$MouseMap.hide()
	$DebugMap.hide()
	$WastelandMap.hide()
	$MapPolitical.hide()
	$MapLocal.hide()
	$MapGlobal.show()
	curMap.show()
	
	# Initialise shader parameters
	var provColors: Array = []
	provColors.resize(NUM_PROV)
	provColors.fill(Color.TRANSPARENT)
	initMat(provColors, matLocal)
	initMat(provColors, matGlobal)
	initMat(provColors, matPolitical)
	
	# Load stuff onto provinces
	for prov in GameData.provinces:
		if prov._center == Vector2(-1,-1):
			print("Province is a WIP")
			continue
		prov._soldiers = prov._id # DEBUG
		prov._owner = 0 # DEBUG
		var newSold: Soldier_UI = Soldier_UI.new_soldier(prov._id, true)
		#newSold.visibility_layer = 1 # IDK why this is here...
		# Center the label
		#var spriteSize: Vector2 = newSold.get_child(0).get_rect().size # Probs wrong
		#newSold.position -= Vector2(spriteSize.x/2, spriteSize.y/2) # Probs wrong
		$SoldierObjs.add_child(newSold)

func initMat(provColors: Array, mat: Material):
	mat.set_shader_parameter("base_color", Color8(100,0,0))
	mat.set_shader_parameter("num_of_provinces", NUM_PROV)
	mat.set_shader_parameter("colors", provColors)

func _on_info_updated(provID: int):
	pass

func set_prov_colors(provIDs: Array, colors: Array, mat: Material):
	var extracted: Array = mat.get_shader_parameter("colors")
	print(matLocal)
	print(matGlobal)
	print(matPolitical)
	print(mat)
	for i in range(len(provIDs)):
		extracted[provIDs[i]] = colors[i]
	mat.set_shader_parameter("colors", extracted)

func set_prov_color(provID: int, color: Color, mat: Material):
	var extracted: Array = mat.get_shader_parameter("colors")
	print(str(GameData.localPlayerIndex) + ": b4: " + str(extracted))
	extracted[provID] = color
	print(str(GameData.localPlayerIndex) + ": AFTER: " + str(extracted))
	mat.set_shader_parameter("colors", extracted)

func _on_new_map_prov(oldProvID: int, newProvID: int):
	print(str(GameData.localPlayerIndex) + ": " + "NEW GAME PROVINCE SELECTED") # DEBUG
	if(oldProvID == newProvID):
		return
	# Color out the previous province
	if oldProvID != GameData.Province.WASTELAND_ID:
		set_prov_color(oldProvID, Color.TRANSPARENT, matGlobal)	
	# Color in the new province
	if newProvID != GameData.Province.WASTELAND_ID and \
	   GameData.turnPlayerIndex != GameData.localPlayerIndex:
		set_prov_color(newProvID, GameData.GAME_SEL_COLOR, matGlobal)


func _on_prov_clicked(oldProvID: int, newProvID: int):
	print(str(GameData.localPlayerIndex) + ": " +  "PROV CLICKED")
	if(oldProvID == newProvID):
		return
	# Color out previous province(s)
	if oldProvID != GameData.Province.WASTELAND_ID:
		var oldProv = GameData.provinces[oldProvID]
		var provIDs: Array = []
		provIDs.append(oldProvID)
		provIDs.append_array(oldProv._neighbors)
		var colors: Array = []
		colors.resize(len(provIDs))
		colors.fill(Color.TRANSPARENT)
		set_prov_colors(provIDs, colors, matLocal)
	
	# Color in new province(s)
	if newProvID != GameData.Province.WASTELAND_ID:
		var newProv = GameData.provinces[newProvID]
		var provIDs: Array = []
		provIDs.append(newProvID)
		provIDs.append_array(newProv._neighbors)
		var colors: Array = []
		colors.resize(len(provIDs))
		colors.fill(GameData.NEIGH_COLOR)
		colors[0] = GameData.SEL_COLOR
		set_prov_colors(provIDs, colors, matLocal)
