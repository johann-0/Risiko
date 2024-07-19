extends Camera2D

@export var CAM_SPEED = 600.0
@export var ZOOM_SPEED = 1.4
const ZOOM_MIN = 1.1
const ZOOM_MAX = 7
# Corners of the (left) sprite
@export var map : Node2D
@onready var mouseMap = map.get_child(0)
@onready var SPRITE_X = mouseMap.position.x
@onready var SPRITE_Y = mouseMap.position.y
# Dimensions of the sprite
@onready var SPRITE_WIDTH = mouseMap.texture.get_width()
@onready var SPRITE_HEIGHT = mouseMap.texture.get_height()
# Corners of the game map
@onready var PAN_MIN_Y = SPRITE_Y
@onready var PAN_MAX_Y = SPRITE_Y + SPRITE_HEIGHT


# Called when the node enters the scene tree for the first time.
func _ready():
	capZoom()
	capPosition()


func _process(delta):
	handle_zooming(delta)
	handle_panning(delta)


func handle_panning(delta):
	if Input.is_action_pressed("pan_right"):
		position.x += CAM_SPEED * delta / zoom.x
	if Input.is_action_pressed("pan_left"):
		position.x -= CAM_SPEED * delta / zoom.x
	if Input.is_action_pressed("pan_down"):
		position.y += CAM_SPEED * delta / zoom.y
	if Input.is_action_pressed("pan_up"):
		position.y -= CAM_SPEED * delta / zoom.y
	
	# Check for panning with the mouse
	capPosition()
	
	

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		position -= event.relative / zoom
	capPosition()

func handle_zooming(delta):
	# Position of the mouse relative to the camera before zooming
	var dist_before = global_position - get_global_mouse_position()
	var zoomed = false
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom *= Vector2(ZOOM_SPEED, ZOOM_SPEED)
		zoomed = true
	elif Input.is_action_just_pressed("zoom_out"):
		zoom /= Vector2(ZOOM_SPEED, ZOOM_SPEED)
		zoomed = true
	
	capZoom()
	
	if zoomed == false:
		return
	
	# After zooming, move the camera so we zoom around the mouse
	var dist_now = global_position - get_global_mouse_position()
	global_position += dist_now - dist_before


func capPosition():
	position.y = max(position.y, PAN_MIN_Y)
	position.y = min(position.y, PAN_MAX_Y - (get_viewport_rect().size.y)/zoom.y)
	
	# Move camera left if near right border (sprite_width * 2)
	var mostRightX = global_position.x + get_viewport_rect().size.x
	if mostRightX + 10 >= SPRITE_X + 2 * SPRITE_WIDTH:
		position.x -= SPRITE_WIDTH
	# Move camera right if near left border (0)
	var mostLeftX = global_position.x
	if mostLeftX - 10 < SPRITE_X:
		position.x += SPRITE_WIDTH


func capZoom():
	zoom.x = max(zoom.x, ZOOM_MIN)
	zoom.y = max(zoom.y, ZOOM_MIN)
	zoom.x = min(zoom.x, ZOOM_MAX)
	zoom.y = min(zoom.y, ZOOM_MAX)
