class_name Die
extends TextureRect

enum State { fixed, rolling }

const TIME_PER_FRAME: float = 0.1

var number: int = 1:
	set(newNum):
		number = newNum
		texture.region.position.x = (newNum-1) * 8
var roll_randomly: bool = false
var state: State = State.fixed
var timeout: float = 0.0

func _ready() -> void:
	randomize_num()
	state = State.fixed

func roll(_roll_randomly: bool) -> void:
	roll_randomly = _roll_randomly
	state = State.rolling

func stop_roll() -> void:
	state = State.fixed

func _process(delta) -> void:
	if state != State.rolling: return
	
	timeout += delta
	if timeout < TIME_PER_FRAME: return
	
	timeout -= TIME_PER_FRAME
	if roll_randomly: randomize_num()
	else: increment_num()

func randomize_num() -> void:
	number = randi() % 6 + 1

func increment_num() -> void:
	number = (number + 1) % 6 + 1
