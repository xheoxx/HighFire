# =============================================================================
# DATEINAME: motion_input_parser.gd
# ZWECK:     Erkennung von Motion-Inputs (D-Pad + Analogstick), L/R-Tippen-
#            Halten-Logik und Combo-Pattern-Matching fuer Modus L/R/B.
#            Emittiert Signale fuer Target-Management, Combo-Erkennung und
#            Perfect-Timing-Faelle.
# ABHAENGIG VON: resources/combo_definitions.tres, project.godot Input-Actions,
#                optional scripts/combo_chain.gd (visuales Feedback)
# =============================================================================

class_name MotionInputParser
extends Node

# Wird gesendet wenn ein Combo-Modus umgeschaltet wurde.
# mode verwendet das Enum ComboMode in diesem Script.
signal combo_mode_changed(mode: int)

# Wird gesendet wenn eine gueltige Combo erkannt wurde.
# combo_name: Name aus combo_definitions.tres oder Sequenzname fuer Modus L.
signal combo_recognized(combo_name: String, mode: int)

# Wird gesendet wenn die erkannte Geste schneller als PERFECT_WINDOW war.
signal perfect_input(combo_name: String, mode: int, duration: float)

# Target-Management-Signale fuer Target-System.
signal target_prev_requested()
signal target_next_requested()
signal target_lock_requested()

# Wird gesendet wenn ein Input-Pattern nicht fortgesetzt werden kann.
signal input_failed(mode: int)

# Wird fuer UI/VFX pro aufgenommenem Richtungs-Input gesendet.
signal combo_step_added(direction: int)

# Kombi-Modi nach DESIGN.md.
enum ComboMode {
	NONE,
	MODE_L,
	MODE_R,
	MODE_B,
}

# 8-Richtungs-Enum fuer Gesten.
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	UP_RIGHT,
	UP_LEFT,
	DOWN_RIGHT,
	DOWN_LEFT,
}

# Prefix-Mapping fuer Input-Actions pro Spieler.
const ACTION_PREFIXES: Array[String] = ["p1_", "p2_", "p3_", "p4_"]

# Tap-vs-Hold-Schwelle nach PLAN/DESIGN (200ms).
const TAP_THRESHOLD: float = 0.2

# Fenster fuer Perfect-Timing-Bonus.
const PERFECT_WINDOW: float = 0.15

# Modusabhaengige Zeitfenster fuer Ring-Buffer.
const WINDOW_MODE_LR: float = 0.4
const WINDOW_MODE_B: float = 0.6

# Anzahl gespeicherter Richtungen im Ring-Buffer.
const MAX_BUFFER_SIZE: int = 8

# Analogstick-Deadzone fuer Richtungsquantisierung.
const DEFAULT_ANALOG_DEADZONE: float = 0.195

# Export: Spieler-Slot fuer Action-Prefix (0 bis 3).
@export_range(0, 3) var player_id: int = 0

# Optionaler Verweis auf Combo-Chain-Visual.
@export var combo_chain_path: NodePath

# Geladene Combo-Definitionen (mode_r_sequences / mode_b_sequences).
var _combo_definitions: Resource

# Dictionaries fuer Sequenz-Mapping aus Resource.
var _mode_r_sequences: Dictionary = {}
var _mode_b_sequences: Dictionary = {}

# Letzte Richtungs-Inputs: {"direction": int, "time": float}.
var _input_buffer: Array[Dictionary] = []

# Aktueller Modus (NONE/L/R/B).
var _current_mode: int = ComboMode.NONE

# Laufende Zeit fuer zeitbasierte Fensterpruefung.
var _elapsed_time: float = 0.0

# Laufender Mode-Timer fuer aktuelle Geste (Startzeit des ersten Steps).
var _gesture_start_time: float = -1.0

# Action-Prefix fuer den aktuellen Spieler.
var _action_prefix: String = "p1_"

# Zustand der L/R-Schultertasten.
var _l_pressed: bool = false
var _r_pressed: bool = false
var _l_press_time: float = -1.0
var _r_press_time: float = -1.0
var _l_hold_activated: bool = false
var _r_hold_activated: bool = false

# Pending-Tap-Zeiten fuer L/R-Tap-Kombination (Target-Lock).
var _pending_tap_l_time: float = -1.0
var _pending_tap_r_time: float = -1.0

# Letzte quantisierte Analogrichtung (verhindert Duplikat-Spam).
var _last_analog_direction: int = -1

# Frame-Marker: wurde in diesem Frame bereits ein digitaler Schritt erfasst?
var _digital_step_frame: int = -1

# Referenz auf optionale Combo-Chain-Node.
var _combo_chain: Node

# Laedt Resource, setzt Prefix und verbindet optionale UI-Node.
func _ready() -> void:
	_action_prefix = ACTION_PREFIXES[player_id]
	_combo_definitions = load("res://resources/combo_definitions.tres")
	if _combo_definitions:
		_mode_r_sequences = _combo_definitions.get("mode_r_sequences") if _combo_definitions.get("mode_r_sequences") else {}
		_mode_b_sequences = _combo_definitions.get("mode_b_sequences") if _combo_definitions.get("mode_b_sequences") else {}

	if combo_chain_path != NodePath():
		_combo_chain = get_node_or_null(combo_chain_path)

# Zeitbasierte Pruefungen fuer Hold-Aktivierung, Buffer-Fenster und Analog-Input.
func _process(delta: float) -> void:
	_elapsed_time += delta
	_update_hold_activation()
	_prune_buffer_by_time()
	_capture_analog_direction()

# Verarbeitet digitale InputEvents fuer L/R und D-Pad.
func _input(event: InputEvent) -> void:
	_handle_shoulder_input(event)
	_handle_dpad_input(event)

# Aktiviert Combo-Modi sobald L/R laenger als TAP_THRESHOLD gehalten werden.
func _update_hold_activation() -> void:
	if _l_pressed and not _l_hold_activated and (_elapsed_time - _l_press_time) >= TAP_THRESHOLD:
		_l_hold_activated = true
		_apply_mode_from_holds()

	if _r_pressed and not _r_hold_activated and (_elapsed_time - _r_press_time) >= TAP_THRESHOLD:
		_r_hold_activated = true
		_apply_mode_from_holds()

# Setzt den aktiven Modus aus dem aktuellen Hold-Zustand.
func _apply_mode_from_holds() -> void:
	var new_mode: int = ComboMode.NONE
	if _l_hold_activated and _r_hold_activated:
		new_mode = ComboMode.MODE_B
	elif _l_hold_activated:
		new_mode = ComboMode.MODE_L
	elif _r_hold_activated:
		new_mode = ComboMode.MODE_R

	if new_mode != _current_mode:
		_set_combo_mode(new_mode)

# Schaltet Modus um und leert den Buffer bei Moduswechsel.
func _set_combo_mode(new_mode: int) -> void:
	_current_mode = new_mode
	_clear_buffer()
	combo_mode_changed.emit(_current_mode)

# Verarbeitet L/R Press/Release fuer Tap-vs-Hold-Logik.
func _handle_shoulder_input(event: InputEvent) -> void:
	if event.is_action_pressed(_action_prefix + "combo_mode_l"):
		_l_pressed = true
		_l_press_time = _elapsed_time
		_l_hold_activated = false

	if event.is_action_pressed(_action_prefix + "combo_mode_r"):
		_r_pressed = true
		_r_press_time = _elapsed_time
		_r_hold_activated = false

	if event.is_action_released(_action_prefix + "combo_mode_l"):
		_process_l_release()

	if event.is_action_released(_action_prefix + "combo_mode_r"):
		_process_r_release()

# Behandelt L-Release inkl. Tap-Handling und Mode-Reset.
func _process_l_release() -> void:
	_l_pressed = false
	var held: float = _elapsed_time - _l_press_time
	var was_hold: bool = _l_hold_activated
	_l_hold_activated = false

	if not was_hold and held < TAP_THRESHOLD:
		_handle_l_tap()

	_apply_mode_from_holds()

# Behandelt R-Release inkl. Tap-Handling und Mode-Reset.
func _process_r_release() -> void:
	_r_pressed = false
	var held: float = _elapsed_time - _r_press_time
	var was_hold: bool = _r_hold_activated
	_r_hold_activated = false

	if not was_hold and held < TAP_THRESHOLD:
		_handle_r_tap()

	_apply_mode_from_holds()

# L-Tap: Normalmodus = target_prev, Modus R = experimenteller Zielwechsel.
func _handle_l_tap() -> void:
	if _current_mode == ComboMode.MODE_R:
		target_prev_requested.emit()
		return

	if _current_mode == ComboMode.NONE:
		_pending_tap_l_time = _elapsed_time
		target_prev_requested.emit()
		_try_emit_target_lock()

# R-Tap: Normalmodus = target_next, Modus L = experimenteller Zielwechsel.
func _handle_r_tap() -> void:
	if _current_mode == ComboMode.MODE_L:
		target_next_requested.emit()
		return

	if _current_mode == ComboMode.NONE:
		_pending_tap_r_time = _elapsed_time
		target_next_requested.emit()
		_try_emit_target_lock()

# Erzeugt target_lock wenn L- und R-Tap zeitlich nahe genug waren.
func _try_emit_target_lock() -> void:
	if _pending_tap_l_time < 0.0 or _pending_tap_r_time < 0.0:
		return

	if abs(_pending_tap_l_time - _pending_tap_r_time) <= TAP_THRESHOLD:
		target_lock_requested.emit()
		_pending_tap_l_time = -1.0
		_pending_tap_r_time = -1.0

# Erfasst digitale D-Pad-InputEvents und wandelt sie in Richtungssteps um.
func _handle_dpad_input(event: InputEvent) -> void:
	if _current_mode == ComboMode.NONE:
		return

	var direction: int = -1
	if event.is_action_pressed(_action_prefix + "move_up"):
		direction = Direction.UP
	elif event.is_action_pressed(_action_prefix + "move_down"):
		direction = Direction.DOWN
	elif event.is_action_pressed(_action_prefix + "move_left"):
		direction = Direction.LEFT
	elif event.is_action_pressed(_action_prefix + "move_right"):
		direction = Direction.RIGHT

	if direction >= 0:
		_digital_step_frame = Engine.get_process_frames()
		_add_direction_step(direction)

# Erfasst quantisierte Analog-Richtung (8-way) bei Richtungswechseln.
func _capture_analog_direction() -> void:
	if _current_mode == ComboMode.NONE:
		_last_analog_direction = -1
		return

	if _digital_step_frame == Engine.get_process_frames():
		return

	var x_strength: float = Input.get_action_strength(_action_prefix + "move_right") - Input.get_action_strength(_action_prefix + "move_left")
	var y_strength: float = Input.get_action_strength(_action_prefix + "move_down") - Input.get_action_strength(_action_prefix + "move_up")
	var analog_vector := Vector2(x_strength, y_strength)

	var analog_deadzone: float = DEFAULT_ANALOG_DEADZONE
	if _combo_definitions and _combo_definitions.get("analog_deadzone") != null:
		analog_deadzone = float(_combo_definitions.get("analog_deadzone"))

	var quantized: int = _quantize_direction(analog_vector, analog_deadzone)
	if quantized == -1:
		_last_analog_direction = -1
		return

	if quantized != _last_analog_direction:
		_last_analog_direction = quantized
		_add_direction_step(quantized)

# Fuegt einen Richtungsstep in den Ring-Buffer ein und prueft Pattern.
func _add_direction_step(direction: int) -> void:
	if _gesture_start_time < 0.0:
		_gesture_start_time = _elapsed_time

	_input_buffer.append({
		"direction": direction,
		"time": _elapsed_time,
	})

	var max_buffer: int = MAX_BUFFER_SIZE
	if _combo_definitions and _combo_definitions.get("ring_buffer_size") != null:
		max_buffer = int(_combo_definitions.get("ring_buffer_size"))
	while _input_buffer.size() > max_buffer:
		_input_buffer.pop_front()

	combo_step_added.emit(direction)
	_push_to_combo_chain(direction)
	_prune_buffer_by_time()
	_evaluate_pattern_match()

# Entfernt alte Eintraege ausserhalb des aktiven Zeitfensters.
func _prune_buffer_by_time() -> void:
	if _input_buffer.is_empty():
		return

	var window: float = _get_active_window()
	while not _input_buffer.is_empty() and (_elapsed_time - float(_input_buffer[0]["time"])) > window:
		_input_buffer.pop_front()

	if _input_buffer.is_empty():
		_gesture_start_time = -1.0

# Liefert das Zeitfenster fuer den aktuellen Modus.
func _get_active_window() -> float:
	if _current_mode == ComboMode.MODE_B:
		return WINDOW_MODE_B
	if _current_mode == ComboMode.MODE_L or _current_mode == ComboMode.MODE_R:
		return WINDOW_MODE_LR
	return WINDOW_MODE_LR

# Prueft auf vollen Match bzw. Prefix und behandelt Fehlversuche.
func _evaluate_pattern_match() -> void:
	var current_key: String = _current_sequence_key()
	if current_key.is_empty():
		return

	var sequence_map: Dictionary = _get_active_sequence_map()

	if _current_mode == ComboMode.MODE_L:
		# Modus L ist in Stream A als Parser-Stufe generisch:
		# Bei exakt 2 Eingaben wird die Sequenz als combo_recognized emittiert.
		if _input_buffer.size() == 2:
			_emit_combo_success("mode_l:" + current_key)
		return

	if sequence_map.has(current_key):
		_emit_combo_success(String(sequence_map[current_key]))
		return

	var has_prefix: bool = _has_prefix(sequence_map, current_key)
	if not has_prefix:
		input_failed.emit(_current_mode)
		_clear_buffer()

# Gibt die Sequenz-Map fuer den aktiven Modus zurueck.
func _get_active_sequence_map() -> Dictionary:
	if _current_mode == ComboMode.MODE_R:
		return _mode_r_sequences
	if _current_mode == ComboMode.MODE_B:
		return _mode_b_sequences
	return {}

# Prueft ob current_key Prefix eines vorhandenen Combo-Keys ist.
func _has_prefix(sequence_map: Dictionary, current_key: String) -> bool:
	for key in sequence_map.keys():
		var candidate: String = String(key)
		if candidate.begins_with(current_key):
			return true
	return false

# Baut den aktuellen Buffer in ein Key-Format wie "DOWN,RIGHT" um.
func _current_sequence_key() -> String:
	if _input_buffer.is_empty():
		return ""

	var parts: Array[String] = []
	for entry in _input_buffer:
		parts.append(_direction_name(int(entry["direction"])))
	return ",".join(parts)

# Emittiert Combo- und Perfect-Signale und leert den Buffer.
func _emit_combo_success(combo_name: String) -> void:
	combo_recognized.emit(combo_name, _current_mode)

	if _gesture_start_time >= 0.0:
		var duration: float = _elapsed_time - _gesture_start_time
		if duration < PERFECT_WINDOW:
			perfect_input.emit(combo_name, _current_mode, duration)

	_clear_buffer()

# Leert Buffer/Gesture-State und setzt optionale Visualisierung zurueck.
func _clear_buffer() -> void:
	_input_buffer.clear()
	_gesture_start_time = -1.0
	if _combo_chain and _combo_chain.has_method("clear_chain"):
		_combo_chain.call("clear_chain")

# Leitet neuen Richtungsstep an combo_chain.gd weiter (falls gesetzt).
func _push_to_combo_chain(direction: int) -> void:
	if _combo_chain and _combo_chain.has_method("add_direction"):
		_combo_chain.call("add_direction", direction)

# Quantisiert einen Vektor in 8 Richtungen; -1 bedeutet "kein Input".
func _quantize_direction(vec: Vector2, deadzone: float) -> int:
	if vec.length() <= deadzone:
		return -1

	var angle: float = vec.angle()
	var sector: int = int(round(angle / (PI / 4.0)))
	sector = posmod(sector, 8)

	match sector:
		0:
			return Direction.RIGHT
		1:
			return Direction.DOWN_RIGHT
		2:
			return Direction.DOWN
		3:
			return Direction.DOWN_LEFT
		4:
			return Direction.LEFT
		5:
			return Direction.UP_LEFT
		6:
			return Direction.UP
		7:
			return Direction.UP_RIGHT
	return -1

# Liefert den Enum-Namen fuer die Resource-Key-Generierung.
func _direction_name(direction: int) -> String:
	match direction:
		Direction.UP:
			return "UP"
		Direction.DOWN:
			return "DOWN"
		Direction.LEFT:
			return "LEFT"
		Direction.RIGHT:
			return "RIGHT"
		Direction.UP_RIGHT:
			return "UP_RIGHT"
		Direction.UP_LEFT:
			return "UP_LEFT"
		Direction.DOWN_RIGHT:
			return "DOWN_RIGHT"
		Direction.DOWN_LEFT:
			return "DOWN_LEFT"
	return "UNKNOWN"

# Externe API: setzt den Spieler-Slot neu (z. B. bei Spawner-Reassign).
func set_player_id(new_player_id: int) -> void:
	player_id = clamp(new_player_id, 0, 3)
	_action_prefix = ACTION_PREFIXES[player_id]
	_clear_buffer()

# Externe API: liefert aktuellen Combo-Modus.
func get_current_mode() -> int:
	return _current_mode
