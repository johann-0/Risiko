extends Node2D

@onready var curMap: Sprite2D = $WastelandMap
@onready var mat: Material = $OverlayMap.material # For all overlaying layers
@onready var NUM_PROV: int = GameData.NUM_PROV
@onready var mask: Array[Array] = [] # 0 = Global, 1 = Local, 2 = Political

signal map_prov_clicked(provID: int)

enum Mask {Glo = 2, Loc = 1, Pol = 0} # Global, Local, Political

func _ready() -> void:
	# Connect to signals
	GameData.new_loc_sel_prov.connect(_on_new_loc_sel_prov)
	GameData.new_glo_sel_prov.connect(_on_new_glo_sel_prov)
	GameData.new_glo_att_prov.connect(_on_new_glo_att_prov)
	GameData.new_turn.connect(_on_new_turn)
	for province in GameData.provinces:
		province.infoUpdated.connect(_on_prov_info_updated)
	
	# Hide all maps except Map and curMap
	$MouseMap.hide()
	$DebugMap.hide()
	$WastelandMap.hide()
	$OverlayMap.show()
	curMap.show()
	
	# Initialize mask
	for i in range(Mask.size()):
		var newArr: Array[Color] = []
		newArr.resize(NUM_PROV)
		newArr.fill(Color.TRANSPARENT)
		mask.append(newArr)
	# Initialize shader
	apply_mask()
	mat.set_shader_parameter("base_color", Color8(100,0,0))
	mat.set_shader_parameter("num_of_provinces", NUM_PROV)
	
	# Load stuff onto provinces
	for prov in GameData.provinces:
		var newSold: Soldier_UI = Soldier_UI.new_soldier(prov._id, true)
		#newSold.visibility_layer = 1 # IDK why this is here...
		$SoldierObjs.add_child(newSold)

func foldMask() -> Array[Color]:
	var toReturn: Array[Color] = []
	for i in range(NUM_PROV):
		var toAdd: Color = Color8(0,0,0,0)
		for j in range(Mask.size()):
			toAdd = toAdd.blend(mask[j][i])
		toReturn.append(toAdd)
	return toReturn

func reset_mask(maskLevel: int) -> void:
	var colors: Array = []
	colors.resize(NUM_PROV)
	colors.fill(Color.TRANSPARENT)
	var provIDs: Array = []
	for i in NUM_PROV:
		provIDs.append(i)
	set_mask_colors(provIDs, colors, maskLevel)
	
func set_mask_color(id: int, color: Color, maskLevel: Mask) -> void:
	mask[maskLevel][id] = color
func set_mask_colors(ids: Array, colors: Array, maskLevel: Mask) -> void:
	for i in range(len(ids)):
		mask[maskLevel][ids[i]] = colors[i]
func apply_mask() -> void:
	mat.set_shader_parameter("colors", foldMask())

func _on_prov_info_updated(provID: int) -> void: # Update the political map
	var _owner = GameData.provinces[provID]._owner
	if _owner == -1:
		set_mask_color(provID, Color.TRANSPARENT, 2) # 2=Political
	else:
		var color: Color = GameData.players[_owner]._color
		color = color.darkened(0.4) # 0.2 means 20% darker
		set_mask_color(provID, color, 2) # 2=Political
	apply_mask()

func _on_new_glo_sel_prov(oldProvID: int, newProvID: int) -> void:
	if oldProvID == newProvID:
		return
	# Color out the previous province
	if oldProvID != GameData.Province.WASTELAND_ID:
		set_mask_color(oldProvID, Color.TRANSPARENT, 0) # 0=Global
		apply_mask()
	# Color in the new province
	if newProvID != GameData.Province.WASTELAND_ID and \
	   GameData.turnPlayerIndex != GameData.localPlayerIndex:
		set_mask_color(newProvID, GameData.GAME_SEL_COLOR, 0) # 0=Global
		apply_mask()

func _on_new_glo_att_prov(oldProvID: int, newProvID: int) -> void:
	if oldProvID == newProvID:
		return
	# Color out any previous attacked province
	if oldProvID != GameData.Province.WASTELAND_ID:
		set_mask_color(oldProvID, Color.TRANSPARENT, 0) # 0=Global
		apply_mask()
	# Color in the new attacked province
	if newProvID != GameData.Province.WASTELAND_ID:
		set_mask_color(newProvID, GameData.GAME_ATT_COLOR, 0) # 0=Global
		apply_mask()

func _on_new_turn(_oldIdx,_newIdx,_idxChgd,_oldPhase,_newPhase:GameData.Phase,_phaseChanged) -> void:
	# Reset the global mask
	match _oldPhase:
		GameData.Phase.init_deploy:
			reset_mask(0) # 0=Global
		GameData.Phase.deploy:
			pass#set_mask_color(GameData.gameSelectedProvID, Color.TRANSPARENT, 0) # 0=Global
		GameData.Phase.attack:
			set_mask_color(GameData.gameAttackedProvID, Color.TRANSPARENT, 0) # 0=Global
		GameData.Phase.fortify:
			set_mask_color(GameData.gameAttackedProvID, Color.TRANSPARENT, 0) # 0=Global
		_:
			pass
	apply_mask()

func _on_new_loc_sel_prov(oldProvID: int, newProvID: int) -> void:
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
		set_mask_colors(provIDs, colors, 1) # 1=Local
		apply_mask()
	
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
		set_mask_colors(provIDs, colors, 1) # 1=Local
		apply_mask()
