extends Node2D

var game_state = Globals.GameState.EXPLORING

@onready var map_manager := $map_manager
@onready var encounter_manager := $encounter_manager
@onready var input_manager := $input_manager
@onready var menu := $menu

# GameFeel
var ignore_input := false


func _ready() -> void:
	# Initialize encounter manager logic
	encounter_manager.thresholds_initialized.connect(_on_thresholds_initialized)
	encounter_manager.state_changed.connect(_on_state_changed)
	encounter_manager.initialize_thresholds()

	# Initialize input managers
	input_manager.move_requested.connect(_on_move_requested)
	menu.save_file_requested.connect(_on_save_file_requested)
	menu.load_file_requested.connect(_on_load_file_requested)
	menu.strafe_mode_toggled.connect(_on_strafe_mode_toggled)
	menu.restart_requested.connect(_on_restart_requested)
	menu.export_requested.connect(_on_export_requested)
	# Set initial strafe mode
	_on_strafe_mode_toggled(true)

	# Set up post-move signal
	map_manager.player_moved.connect(_on_player_moved)


func _on_thresholds_initialized():
	_update_display()


func _on_state_changed(color: Color) -> void:
	encounter_manager.modulate = color
	$info/steps_left.modulate = color
	$info/steps_left_lbl.modulate = color
	map_manager.change_pip_color(color)


func _on_move_requested(direction):
	map_manager.move_if_possible(direction)


func _on_save_file_requested():
	map_manager.save_map()


func _on_load_file_requested():
	map_manager.load_map()


func _on_strafe_mode_toggled(toggle: bool) -> void:
	map_manager.toggle_strafe_mode(toggle)
	input_manager.toggle_strafe_mode(toggle)


func _on_restart_requested() -> void:
	if game_state != Globals.GameState.EDITING:
		encounter_manager.reset_thresholds()
		map_manager.reset_map()
		input_manager.reset_defaults()
		game_state = Globals.GameState.EXPLORING


func _on_export_requested() -> void:
	map_manager.export_map()


func _on_player_moved():
	if encounter_manager.steps_left_until_encounter <= 0:
		return
	encounter_manager.add_step()
	_update_display()


func _update_display() -> void:
	var total_steps = encounter_manager.steps_taken
	var steps_left = encounter_manager.steps_left_until_encounter
	$info/total_steps.text = str(total_steps).pad_zeros(2)
	$info/steps_left.text = str(steps_left).pad_zeros(2)
