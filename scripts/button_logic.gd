extends TextureButton

signal requested_movement (button_name: String)

# GameFeel: Simulate a button press
func _toggled(toggled_on: bool) -> void:
	if toggled_on:
		await get_tree().create_timer(0.2).timeout
		button_pressed = false
	else:
		requested_movement.emit(name)

func _input(event: InputEvent):

	var action_map := {
			"q": "action1",
			"w": "up",
			"e": "action2",
			"a": "left",
			"s": "down",
			"d": "right"
		}

	if name not in action_map:
		return

	if event.is_action_pressed(action_map[name]) and not event.echo:
		button_pressed = !button_pressed
		get_tree().root.set_input_as_handled()
