extends Node2D

# Node references
@onready var map_pip := $map/pip
@onready var map := $map
@onready var preview := $map/preview
@onready var tile_preview := $map/tile_preview
@onready var camera := $camera
@onready var logger := $logger
# For Display/Debugging
@export var world_coord_label := RichTextLabel
@export var local_coord_label := RichTextLabel
const FILE_PATH := "user://rec_map_data.json"

# FileDialog reference for export functionality
var file_dialog: FileDialog

# Tileset variables
@onready var tileset = map.tile_set
var tiles_array: Array = []
var selected_map_tile:= Vector2i(0, 0)
const DEFAULT_TILE := 0
const SELECTED_TILE := 1
const HOVERED_TILE := 2
# Tile preview hover tracking
var hovered_preview_tile: Vector2i = Vector2i(-1, -1)

# Movement variables
var is_strafing := false

# Editing variables
@export var map_tile_rows := 3
@export var map_tile_columns := 5
var selected_tile_index := Vector2i(0, 0)
var starting_world_pos := Vector2i(14, 1)
var ending_world_pos := Vector2i(27, 11)

# UX Tweaks
# Account for tile placement
var cursor_preview_timer := 0.0
var cursor_preview_delay := 0.2
# Account for mouse wheel scrolling
var wheel_debounce_timer := 0.0
var wheel_debounce_delay := 0.1

# Signals sent to Main node
signal player_moved

func _ready():
	_setup_tile_preview()
	_setup_file_dialog()
	load_map()


func _input(event):
	if event is InputEventMouseButton:
		#region Preview Tile Corner Logic
		var preview_mouse_pos = tile_preview.get_local_mouse_position()
		var preview_grid_pos = tile_preview.local_to_map(preview_mouse_pos)
		var is_over_preview = _is_valid_preview_tile(preview_grid_pos)

		# If clicking on preview area, handle tile selection
		if is_over_preview and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_preview_tile(preview_grid_pos)
			return

		# Convert mouse screen position to tilemap grid coords
		var local_mouse_pos = Vector2i(map.get_local_mouse_position())
		var grid_pos = map.local_to_map(local_mouse_pos)

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if wheel_debounce_timer <= 0:
				_cycle_selected_tile(1)
				wheel_debounce_timer = wheel_debounce_delay
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if wheel_debounce_timer <= 0:
				_cycle_selected_tile(-1)
				wheel_debounce_timer = wheel_debounce_delay
		#endregion

		#region Map Making Logic
		if _mouse_event_is_out_of_bounds(grid_pos):
			return
		elif (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
			and cursor_preview_timer <= 0
		):	# Add tile on left click
			map.set_cell(grid_pos, 0, selected_map_tile, SELECTED_TILE)
			cursor_preview_timer = cursor_preview_delay
			await get_tree().create_timer(0.2).timeout
			map.set_cell(grid_pos, 0, selected_map_tile, DEFAULT_TILE)
			queue_redraw()
		elif (
			event.button_index == MOUSE_BUTTON_RIGHT
			and event.pressed
			and cursor_preview_timer <= 0
		):	# Remove tile on right click
			map.erase_cell(grid_pos)
			queue_redraw()
		#endregion


func _process(_delta: float) -> void:
	_update_hover_info()
	_update_tile_preview_hover()
	_update_timers(_delta)

#region ------------- MOUSE LOGIC ------------------
func _update_timers(delta: float) -> void:
	if wheel_debounce_timer > 0:
		wheel_debounce_timer -= delta
	if cursor_preview_timer > 0:
		preview.clear()
		cursor_preview_timer -= delta


func _update_tile_preview_hover() -> void:
	var preview_mouse_pos = tile_preview.get_local_mouse_position()
	var preview_grid_pos = tile_preview.local_to_map(preview_mouse_pos)
	var is_valid = _is_valid_preview_tile(preview_grid_pos)

	# Remove hover effect from previously hovered tile
	if hovered_preview_tile != Vector2i(-1, -1) and hovered_preview_tile != selected_map_tile:
		tile_preview.set_cell(hovered_preview_tile, 0, hovered_preview_tile, DEFAULT_TILE)

	# Apply hover effect to current tile
	if is_valid:
		hovered_preview_tile = preview_grid_pos
		if preview_grid_pos != selected_map_tile:
			tile_preview.set_cell(preview_grid_pos, 0, preview_grid_pos, HOVERED_TILE)
	else:
		hovered_preview_tile = Vector2i(-1, -1)


func _is_valid_preview_tile(grid_pos: Vector2i) -> bool:
	return (
		grid_pos.x >= 0 and grid_pos.x < map_tile_columns
		and grid_pos.y >= 0 and grid_pos.y < map_tile_rows
	)


func _select_preview_tile(tile_coords: Vector2i) -> void:
	# Remove highlight from previously selected tile
	tile_preview.set_cell(selected_map_tile, 0, selected_map_tile, DEFAULT_TILE)

	# Update selected tile
	selected_map_tile = tile_coords

	# Highlight the newly selected tile
	tile_preview.set_cell(selected_map_tile, 0, selected_map_tile, SELECTED_TILE)

	# Reset hover tracking
	hovered_preview_tile = Vector2i(-1, -1)


func _update_hover_info() -> void:
	var local_mouse_pos = map.get_local_mouse_position()
	var grid_pos = map.local_to_map(local_mouse_pos)
	var coords = _debug_get_mouse_coords(grid_pos)

	world_coord_label.text = coords[0]

	if _mouse_event_is_out_of_bounds(grid_pos):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		local_coord_label.text = "(-, -)"
		preview.clear()
		return
	else:
		# Call attention to anything under the cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		local_coord_label.text = coords[1]

	# Preview the selected tile at 50% opacity
	preview.clear()
	if cursor_preview_timer <= 0:
		preview.set_cell(grid_pos, 0, selected_map_tile, HOVERED_TILE)
		preview.modulate.a = 0.5


func _debug_get_mouse_coords(mouse_pos: Vector2i) -> Array:
	var x = str(mouse_pos.x).pad_zeros(2)
	var y = str(mouse_pos.y).pad_zeros(2)
	var world_pos = "(%s, %s)" % [x, y]

	var tile_array_pos = mouse_pos - starting_world_pos - Vector2i(1, 1)
	x = str(tile_array_pos.x).pad_zeros(2)
	y = str(tile_array_pos.y).pad_zeros(2)
	var local_pos = "(%s, %s)" % [x, y]

	return [world_pos, local_pos]


func _cycle_selected_tile(direction: int) -> void:
	var total_tiles = map_tile_columns * map_tile_rows

	# Convert current tile to linear index
	var current_index = (selected_map_tile.y * map_tile_columns) + selected_map_tile.x

	# Move to next/previous tile
	current_index -= direction

	# Deselect the previous tile
	tile_preview.set_cell(selected_map_tile, 0, selected_map_tile, DEFAULT_TILE)

	# Wrap around
	current_index = current_index % total_tiles
	if current_index < 0:
		current_index += total_tiles

	# Convert back to 2D coordinates
	@warning_ignore("integer_division")
	selected_map_tile = Vector2i(current_index % map_tile_columns, current_index / map_tile_columns)

	# Show the selection in the UI
	tile_preview.set_cell(selected_map_tile, 0, selected_map_tile, SELECTED_TILE)


func _mouse_event_is_out_of_bounds(grid_pos: Vector2i) -> bool:
	var world_x = starting_world_pos.x + 1
	var world_y = starting_world_pos.y + 1
	var before_start = grid_pos.x < world_x or grid_pos.y < world_y
	var after_end = grid_pos.x > ending_world_pos.x or grid_pos.y > ending_world_pos.y
	return before_start or after_end
#endregion

#region ------------- DRAW LOGIC ------------------
func _draw():
	_draw_edit_grid()


func _draw_edit_grid():
	var grid_color = Color.THISTLE
	var grid_width = 1.0

	# Grid dimensions in tiles
	var offset = Vector2(map_pip.tile_size/2, map_pip.tile_size/2)

	# Vertical lines
	for x in range(starting_world_pos.x, ending_world_pos.x + 1):
		var start = map.map_to_local(Vector2i(x, starting_world_pos.y)) + offset
		var end = map.map_to_local(Vector2i(x, ending_world_pos.y)) + offset
		draw_line(start, end, grid_color, grid_width)

	# Horizontal lines
	for y in range(starting_world_pos.y, ending_world_pos.y + 1):
		var start = map.map_to_local(Vector2i(starting_world_pos.x, y)) + offset
		var end = map.map_to_local(Vector2i(ending_world_pos.x, y)) + offset
		draw_line(start, end, grid_color, grid_width)


func _setup_tile_preview():
	for row in range(map_tile_rows):
		for col in range(map_tile_columns):
			var tile_coords = Vector2i(col, row)
			tile_preview.set_cell(tile_coords, 0, tile_coords)
	tile_preview.set_cell(selected_map_tile, 0, selected_map_tile, SELECTED_TILE)
#endregion

#region ------------- MOVE LOGIC ------------------
func toggle_strafe_mode(toggle: bool):
	is_strafing = toggle
	map_pip.toggle_turn_mode(toggle)


func move_if_possible(direction: Vector2i):
	var has_moved = false
	if is_strafing:
		has_moved = map_pip.strafe_move_if_possible(direction)
	else:
		has_moved = map_pip.move_if_possible(direction)

	if has_moved:
		# Signal that post-move things can be done:
		player_moved.emit()
#endregion

#region ------------- PIP LOGIC ------------------
func change_pip_color(color: Color):
	map_pip.modulate = color


func reset_pip_state():
	map_pip.grid_pos = map_pip.starting_tile
	map_pip._put_sprite_on_tile(map_pip.starting_tile)
	map_pip.facing_direction = Globals.DIR_UP
	map_pip.move_state = Globals.MoveState.STATIC
#endregion

#region ------------- I/O LOGIC ------------------
func reset_map() -> void:
	logger.text = "Starting New Map"
	# Maybe establish new starting point for pip?
	reset_pip_state()
	# Remove all cells
	for x in range(starting_world_pos.x, ending_world_pos.x + 1):
		for y in range(starting_world_pos.y, ending_world_pos.y + 1):
			var grid_pos = Vector2i(x,y)
			map.erase_cell(grid_pos)


func save_map() -> void:
	var room_coordinates := {}
	var room_num := 0

	for x in range(starting_world_pos.x, ending_world_pos.x + 1):
		for y in range(starting_world_pos.y, ending_world_pos.y + 1):
			var grid_pos = Vector2i(x,y)
			var room = "room_%s" % str(room_num).pad_zeros(2)
			var cell_data = map.get_cell_source_id(grid_pos)
			var atlas_coords = map.get_cell_atlas_coords(grid_pos)
			room_coordinates[room]={
				"tile_coords": {"x": grid_pos.x, "y": grid_pos.y},
				"cell_data": cell_data,
				"atlas_coords": {"x": atlas_coords.x, "y": atlas_coords.y}
			}

			room_num += 1

	# Save to project directory
	var json_string = JSON.stringify(room_coordinates)

	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

		var save_path = FILE_PATH.replace("user:/", OS.get_user_data_dir())
		_log_success("Saved to %s" % save_path)
	else:
		_log_error("Error saving to user folder! Make sure the directory exists.")


func export_map() -> void:
	# Open the File Dialog so user can choose folder to save file
	if file_dialog:
		# Temporarily disable input to the map while dialog is open
		set_process_input(false)
		file_dialog.popup_centered_ratio(0.7)


func _on_file_dialog_visibility_changed() -> void:
	# Re-enable input when dialog is closed
	if not file_dialog.visible:
		set_process_input(true)


func _setup_file_dialog() -> void:
	# Create FileDialog if it doesn't exist
	file_dialog = FileDialog.new()
	add_child(file_dialog)

	# Configure the dialog
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.title = "Select Folder to Export Map"
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM

	# Use native OS dialog (macOS Finder, Windows Explorer, etc.)
	file_dialog.use_native_dialog = true

	# Make it movable and always on top
	file_dialog.transient = false
	file_dialog.always_on_top = true

	# Connect the dialog's signals
	file_dialog.dir_selected.connect(_on_export_folder_selected)
	file_dialog.canceled.connect(_on_export_canceled)
	file_dialog.visibility_changed.connect(_on_file_dialog_visibility_changed)


func _on_export_folder_selected(folder_path: String) -> void:
	# Get the JSON data from the current map
	var room_coordinates := {}
	var room_num := 0

	for x in range(starting_world_pos.x, ending_world_pos.x + 1):
		for y in range(starting_world_pos.y, ending_world_pos.y + 1):
			var grid_pos = Vector2i(x,y)
			var room = "room_%s" % str(room_num).pad_zeros(2)
			var cell_data = map.get_cell_source_id(grid_pos)
			var atlas_coords = map.get_cell_atlas_coords(grid_pos)
			room_coordinates[room]={
				"tile_coords": {"x": grid_pos.x, "y": grid_pos.y},
				"cell_data": cell_data,
				"atlas_coords": {"x": atlas_coords.x, "y": atlas_coords.y}
			}

			room_num += 1

	# Convert to JSON string
	var json_string = JSON.stringify(room_coordinates)

	# Create the export file path
	var export_file_path = folder_path.path_join("rec_map_data.json")

	# Write to the selected folder
	var file := FileAccess.open(export_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		_log_success("Map exported to %s" % export_file_path)
	else:
		_log_error("Error exporting map! Check folder permissions.")


func _on_export_canceled() -> void:
	_log("Export Abort")


func load_map() -> void:
	if FileAccess.file_exists(FILE_PATH):
		var file = FileAccess.open(FILE_PATH, FileAccess.READ)
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		file.close()

		if error == OK:
			var room_data = json.data
			# Process and populate map_data
			for room in room_data:
				var room_info = room_data[room]
				var room_tile_coords = room_info.get("tile_coords")
				var grid_pos = Vector2i(room_tile_coords["x"], room_tile_coords["y"])
				var source_id = room_info["cell_data"]
				if source_id != -1:
					var atlas_coords = room_info.get("atlas_coords")
					var tile_pos = Vector2i(atlas_coords["x"], atlas_coords["y"])
					map.set_cell(grid_pos, 0, tile_pos)
				else:
					map.erase_cell(grid_pos)
			_log_success("Map loaded successfully")
		else:
			_log_error("Error parsing JSON. Error: %s" % error)
	else:
		_log("Starting New Map")


func _log_error(message: String) -> void:
	logger.clear()
	logger.text = "[color=red]%s[/color]" % message


func _log_success(message: String) -> void:
	logger.clear()
	logger.text = "[color=green]%s[/color]" % message


func _log(message: String) -> void:
	logger.clear()
	logger.text = message
#endregion
