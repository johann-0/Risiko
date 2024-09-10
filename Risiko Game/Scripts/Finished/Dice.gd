extends Control

@onready var children: Array[Die] = [$Attack1, $Attack2, $Attack3, $Defend1, $Defend2]

var num_attacking: int = 0
var num_defending: int = 0

var isHidden: bool
var isRolling: bool

func _ready() -> void:
	stop_rolling()
	hide_dice()

func priv_hide_children() -> void:
	for die in children:
		die.hide()

func roll_dice(_randomify: bool) -> void:
	isRolling = true
	for die in children:
		if !die.visible:
			continue
		die.roll(_randomify)

func stop_rolling() -> void:
	isRolling = false
	for die in children:
		if !die.visible:
			continue
		die.stop_roll()

func hide_dice() -> void:
	isHidden = true
	num_attacking = 0
	num_defending = 0
	priv_hide_children()

func show_dice(_attacking: int, _defending: int) -> void:
	isHidden = false
	num_attacking = _attacking
	num_defending = _defending
	for i in range(3):
		if i < num_attacking:
			if children[i].visible == false:
				children[i].randomify()
				children[i].show()
		else:
			children[i].hide()
	for i in range(3, 3 + 2):
		if i < num_defending:
			if children[i].visible == false:
				children[i].randomify()
				children[i].show()
		else:
			children[i].hide()

func set_dice(_data: Array[int]) -> void:
	for i in range(_data.size()):
		children[i].number = _data[i]

func dice_to_array() -> Array[int]:
	var toReturn: Array[int] = []
	for die in children:
		# 0=rolling or invisible, 1-6 is the die's number
		if die.state == Die.State.fixed and die.visible == true:
			toReturn.append(die.number)
		else:
			toReturn.append(0)
	return toReturn
