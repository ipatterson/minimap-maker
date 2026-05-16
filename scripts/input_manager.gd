extends GridContainer

@onready var btn_w = $w
@onready var btn_a = $a
@onready var btn_s = $s
@onready var btn_d = $d
@onready var btn_q = $q
@onready var btn_e = $e

var direction_buttons = []
var strafe_buttons = []

var ignore_input := false

var is_strafing := Globals.MoveState.STATIC

signal move_requested(direction: Vector2i)


func _ready():
	direction_buttons.append_array([btn_e, btn_w, btn_q, btn_a, btn_s, btn_d])
	strafe_buttons.append_array([btn_q, btn_e])

	for button in direction_buttons:
		button.requested_movement.connect(_on_requested_movement)


func set_ignore_input(ignore: bool) -> void:
	ignore_input = ignore

func _on_requested_movement(button_name: String) -> void:
	if ignore_input:
		return

	var direction: Vector2i
	match button_name:
		"q":
			direction = Vector2i.ZERO
		"w":
			direction = Vector2i.UP
		"e":
			direction = Vector2i.ONE
		"a":
			direction = Vector2i.LEFT
		"s":
			direction = Vector2i.DOWN
		"d":
			direction = Vector2i.RIGHT

	move_requested.emit(direction,)

	ignore_input = true
	await get_tree().create_timer(0.2).timeout
	ignore_input = false

func toggle_strafe_mode(toggle: bool) -> void:
	is_strafing = Globals.MoveState.TURNING if toggle else Globals.MoveState.STATIC

	for button in strafe_buttons:
		button.disabled = !toggle

func reset_defaults():
	toggle_strafe_mode(true)
	ignore_input = false
