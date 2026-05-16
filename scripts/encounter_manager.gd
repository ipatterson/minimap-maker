extends RichTextLabel

enum EncounterState {
	BLUE,
	GREEN,
	YELLOW,
	ORANGE,
	RED,
	PINK
}

var encounter_state := EncounterState.BLUE
var state_thresholds := {}
var steps_since_state_change := 0
var steps_left_until_encounter := 0
var steps_taken := 0

signal state_changed(color: Color)
signal encounter_started
signal thresholds_initialized()

# Color mapping for each state
const STATE_COLORS = {
	EncounterState.BLUE: Color.CYAN,
	EncounterState.GREEN: Color.GREEN,
	EncounterState.YELLOW: Color.YELLOW,
	EncounterState.ORANGE: Color.ORANGE,
	EncounterState.RED: Color.RED,
	EncounterState.PINK: Color.PINK
}

const STATE_MESSAGES = {
	EncounterState.BLUE: "So far, so good.",
	EncounterState.GREEN: "What was that?",
	EncounterState.YELLOW: "It's getting closer...",
	EncounterState.ORANGE: "Stay calm...",
	EncounterState.RED: "Oh no!",
	EncounterState.PINK: "(Enter combat state)"
}

func reset_thresholds():
	encounter_state = EncounterState.BLUE
	state_thresholds = {}
	steps_left_until_encounter = 0
	steps_since_state_change = 0
	steps_taken = 0
	initialize_thresholds()

func initialize_thresholds():
	var steps := 0

	steps = randi_range(4, 8)
	state_thresholds[EncounterState.BLUE] = steps
	steps_left_until_encounter += steps

	steps = randi_range(3, 7)
	state_thresholds[EncounterState.GREEN] = steps
	steps_left_until_encounter += steps

	steps = randi_range(2, 6)
	state_thresholds[EncounterState.YELLOW] = steps
	steps_left_until_encounter += steps

	steps = randi_range(2, 4)
	state_thresholds[EncounterState.ORANGE] = steps
	steps_left_until_encounter += steps

	steps = randi_range(1, 3)
	state_thresholds[EncounterState.RED] = steps
	steps_left_until_encounter += steps

	text = STATE_MESSAGES.get(encounter_state, "")
	thresholds_initialized.emit()
	state_changed.emit(STATE_COLORS[encounter_state])

func add_step():
	var threshold: int = state_thresholds.get(encounter_state, 0)
	steps_left_until_encounter -= 1
	steps_since_state_change += 1
	steps_taken += 1

	if steps_since_state_change >= threshold:
		_advance_state()
		steps_since_state_change = 0

func _advance_state() -> void:
	encounter_state = ((encounter_state + 1) % EncounterState.size()) as EncounterState
	state_changed.emit(STATE_COLORS[encounter_state])
	text = STATE_MESSAGES.get(encounter_state, "")

	if steps_taken >= steps_left_until_encounter:
		encounter_started.emit()
