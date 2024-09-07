extends Control

@onready var children: Array[Die] = [$Attack1, $Attack2, $Attack3, $Defend1, $Defend2]

var num_attacking: int = 0
var num_defending: int = 0

enum State { hidden, shown, rolling, results }
var state: State = State.hidden

func _ready():
	hide_dice()

func hide_all_children():
	for die in children:
		die.hide()

func roll_dice(randomify: bool):
	state = State.rolling
	for die in children:
		if !die.visible:
			continue
		die.roll(randomify)

func stop_rolling():
	var toReturn: Array[int] = []
	state = State.results
	for die in children:
		if !die.visible:
			continue
		toReturn.append(die.stop_roll())
	return toReturn

func hide_dice():
	state = State.hidden
	num_attacking = 0
	num_defending = 0
	hide_all_children()

func show_dice(attacking: int, defending: int):
	state = State.shown
	num_attacking = attacking
	num_defending = defending
	#hide_all_children()
	for i in range(num_attacking):
		if !children[i].visible:
			children[i].randomify()
			children[i].show()
	for i in range(num_attacking, 3):
		children[i].hide()
	for i in range(num_defending):
		if !children[i].visible:
			children[i].randomify()
			children[i + 3].show()
	for i in range(3 + num_defending, 3 + 2):
		children[i].hide()

func set_dice(data: Array):
	for i in range(children.size()):
		children[i].number = data[i]

func dice_to_array():
	var toReturn: Array[int] = []
	for die in children:
		# 0=rolling, 1-6 is the die's number
		if die.state == Die.State.fixed and die.visible == true:
			toReturn.append(die.number)
		else:
			toReturn.append(0)
	return toReturn
