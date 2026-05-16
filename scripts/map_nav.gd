extends CharacterBody2D

# These can be changed in the editor
@export var tile_size := 16
@export var starting_tile := Vector2i(0,0)

@export var wasd_pip := Rect2i(116, 36, 8, 8)
@export var strafe_pip := Rect2i(132, 20, 8, 8)

# Toggle Static vs Turning Movement
var move_state = Globals.MoveState.STATIC
var facing_direction = Globals.DIR_UP

# For sprite animation/position
@onready var sprite := $icon
var grid_pos := Vector2i(0,0)
var blink_timer := 0.0
var blink_interval := 0.5

func _ready():
	_put_sprite_on_tile(starting_tile)

func _process(delta):
	_blink_sprite(delta)

func move_sprite(direction: Vector2i):
	var next_pos = grid_pos + direction
	_put_sprite_on_tile(next_pos)

func toggle_turn_mode(toggled_on: bool):
	if toggled_on:
		move_state = Globals.MoveState.TURNING
		# Change sprite to arrow
		sprite.texture.region = strafe_pip
	else:
		move_state = Globals.MoveState.STATIC
		# Change sprite to sphere
		sprite.texture.region = wasd_pip
		facing_direction = Vector2i.UP
		_update_sprite_rotation()


func strafe_move_if_possible(moving_direction: Vector2i) -> bool:
	var has_moved = false
	if moving_direction == Globals.DIR_LEFT or moving_direction == Globals.DIR_RIGHT:
		_adjust_facing(moving_direction)
		return has_moved # no movement, just facing adjustment
	else:
		var direction_map = {
			Vector2i.UP: {
				Globals.STRAFE_RIGHT: Globals.DIR_RIGHT,
				Globals.DIR_UP: Globals.DIR_UP,
				Globals.STRAFE_LEFT: Globals.DIR_LEFT,
				Globals.DIR_DOWN: Globals.DIR_DOWN,
			},
			Vector2i.RIGHT: {
				Globals.STRAFE_RIGHT: Globals.DIR_DOWN,
				Globals.DIR_UP: Globals.DIR_RIGHT,
				Globals.STRAFE_LEFT: Globals.DIR_UP,
				Globals.DIR_DOWN: Globals.DIR_LEFT,
			},
			Vector2i.DOWN: {
				Globals.STRAFE_RIGHT: Globals.DIR_RIGHT,
				Globals.DIR_UP: Globals.DIR_DOWN,
				Globals.STRAFE_LEFT: Globals.DIR_LEFT,
				Globals.DIR_DOWN: Globals.DIR_UP,
			},
			Vector2i.LEFT: {
				Globals.STRAFE_RIGHT: Globals.DIR_UP,
				Globals.DIR_UP: Globals.DIR_LEFT,
				Globals.STRAFE_LEFT: Globals.DIR_DOWN,
				Globals.DIR_DOWN: Globals.DIR_RIGHT,
			},
	}

		var actual_direction = direction_map[facing_direction][moving_direction]
		if actual_direction:
			has_moved = move_if_possible(actual_direction)

		return has_moved


func move_if_possible(direction: Vector2i) -> bool:
	var has_moved = false
	if _player_can_move(grid_pos + direction):
		_put_sprite_on_tile(grid_pos + direction)
		has_moved = true
	return has_moved

# Check for a wall between tiles via raycast
func _player_can_move(pos: Vector2i) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + Vector2(pos - grid_pos) * tile_size
		)

	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _put_sprite_on_tile(new_pos: Vector2i):
	# Capture the tile coordinates
	grid_pos = new_pos

	# Calculate the tile's center position
	@warning_ignore("integer_division")
	var _space = tile_size / 2
	var margin = Vector2i(_space,_space)

	# Move the sprite to the tile
	global_position = (new_pos * tile_size) + margin

func _blink_sprite(delta):
	blink_timer += delta
	if blink_timer >= blink_interval:
		sprite.visible = !sprite.visible
		blink_timer = 0.0

func _adjust_facing(turning_direction: Vector2i):
	# When strafing, we need to account for top-down directions
	var current_direction = facing_direction
	match turning_direction:
		Vector2i.LEFT when current_direction == Vector2i.UP:
			facing_direction = Vector2i.LEFT
		Vector2i.LEFT when current_direction == Vector2i.LEFT:
			facing_direction = Vector2i.DOWN
		Vector2i.LEFT when current_direction == Vector2i.DOWN:
			facing_direction = Vector2i.RIGHT
		Vector2i.LEFT when current_direction == Vector2i.RIGHT:
			facing_direction = Vector2i.UP
		Vector2i.RIGHT when current_direction == Vector2i.UP:
			facing_direction = Vector2i.RIGHT
		Vector2i.RIGHT when current_direction == Vector2i.RIGHT:
			facing_direction = Vector2i.DOWN
		Vector2i.RIGHT when current_direction == Vector2i.DOWN:
			facing_direction = Vector2i.LEFT
		Vector2i.RIGHT when current_direction == Vector2i.LEFT:
			facing_direction = Vector2i.UP

	_update_sprite_rotation()

func _update_sprite_rotation():
	match facing_direction:
		Vector2i.UP:
			sprite.rotation = 0
		Vector2i.RIGHT:
			sprite.rotation = PI / 2  # 90 degrees
		Vector2i.DOWN:
			sprite.rotation = PI  # 180 degrees
		Vector2i.LEFT:
			sprite.rotation = 3 * PI / 2  # 270 degrees
