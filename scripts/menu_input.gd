extends MenuButton

signal save_file_requested
signal load_file_requested
signal strafe_mode_toggled(toggled_on: bool)
signal restart_requested
signal export_requested

const SAVE_INDEX := 0
const LOAD_INDEX := 1
const STRAFE_MODE_INDEX := 2
const RESTART_INDEX := 3
const EXPORT_INDEX := 4

var is_strafe_mode_checked := true

func _ready() -> void:
	# Get the popup menu that contains the items
	var popup = get_popup()

	# Connect the index_pressed signal to handle menu item clicks
	popup.index_pressed.connect(_on_menu_item_pressed)

# Debugging
func _input(event: InputEvent):
	if event.is_action_pressed("debug") and not event.echo:
		get_tree().root.set_input_as_handled()
		_toggle_strafe_mode()

	if event.is_action_pressed("reset") and not event.echo:
		get_tree().root.set_input_as_handled()
		_restart_requested()

func _on_menu_item_pressed(index: int) -> void:
	if index == SAVE_INDEX:
		save_file_requested.emit()
	elif index == LOAD_INDEX:
		load_file_requested.emit()
	elif index == STRAFE_MODE_INDEX:
		_toggle_strafe_mode()
	elif index == RESTART_INDEX:
		_restart_requested()
	elif index == EXPORT_INDEX:
		_export_file_requested()


func _restart_requested():
	restart_requested.emit()

func _toggle_strafe_mode():
	var popup = get_popup()
	is_strafe_mode_checked = !is_strafe_mode_checked
	popup.set_item_checked(STRAFE_MODE_INDEX, is_strafe_mode_checked)
	strafe_mode_toggled.emit(is_strafe_mode_checked)

func _export_file_requested():
	export_requested.emit()
