# =============================================================================
# DATEINAME: player_input.gd
# ZWECK:     Input-Abstraktion fuer alle 4 Spieler-Slots.
#            Kapselt alle InputMap-Abfragen hinter einer einheitlichen API,
#            damit player.gd nie direkt Action-Strings oder Joypad-Indizes
#            kennen muss. Unterstuetzt D-Pad, Analogstick und Tastatur-Fallback.
# ABHAENGIG VON: project.godot (Input-Actions p1_* bis p4_*)
# =============================================================================

class_name PlayerInput
extends Node

# --- Konstanten: Prefix-Liste pro Spieler-Index ---
# Jede Action in project.godot beginnt mit "p1_", "p2_" usw.
# Spieler-Index 0 = P1, Index 1 = P2 usw.
# Muss mit den Actions aus Stream E (project.godot) uebereinstimmen.
const ACTION_PREFIXES: Array[String] = ["p1_", "p2_", "p3_", "p4_"]

# --- Konstante: Deadzone fuer Analogstick ---
# Werte unter diesem Betrag werden ignoriert, um Drift zu vermeiden.
# Lt. DESIGN.md: Deadzone 0.3 fuer Analogstick-Quantisierung.
const ANALOG_DEADZONE: float = 0.3

# --- Flag: Input gesperrt ---
# Wenn true, gibt get_move_vector() Vector2.ZERO zurueck und get_action() false.
# Wird von ArenaStateManager gesetzt (z.B. waehrend Countdown).
# Auch player_input.gd selbst kann es setzen (z.B. bei Betaeubung).
var input_blocked: bool = false

# --- Spieler-Index fuer diese Input-Instanz ---
# Wird in player.gd via player_id gesetzt (_ready oder init()).
# Bestimmt welches Prefix und welchen Joypad-Index diese Instanz nutzt.
var player_id: int = 0

# --- Joypad-Index ---
# -1 = Tastatur-Steuerung (P1 und P2 Fallback).
# >= 0 = Joypad-Nummer aus Input.get_connected_joypads().
# Wird in player.gd oder player_spawner.gd gesetzt.
var joypad_index: int = -1

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Gibt den Bewegungsvektor des Spielers zurueck (normalisiert, -1.0 bis 1.0).
# Wertet D-Pad, Analogstick (linker Stick) und Tastatur aus.
# Gibt Vector2.ZERO zurueck wenn input_blocked = true.
func get_move_vector() -> Vector2:
	# Wenn Input gesperrt ist (Betaeubung, Countdown, etc.) keine Bewegung
	if input_blocked:
		return Vector2.ZERO

	var prefix: String = ACTION_PREFIXES[player_id]

	# --- D-Pad / Tastatur auslesen ---
	# InputMap hat Eintraege fuer p1_move_up, p1_move_down, p1_move_left, p1_move_right.
	# get_action_strength() gibt 0.0 oder 1.0 fuer digitale Inputs zurueck.
	var digital := Vector2(
		Input.get_action_strength(prefix + "move_right") - Input.get_action_strength(prefix + "move_left"),
		Input.get_action_strength(prefix + "move_down") - Input.get_action_strength(prefix + "move_up")
	)

	# Wenn ein digitaler Input aktiv ist, diesen bevorzugen.
	# (D-Pad hat Vorrang vor Analogstick – vermeidet Konflikte)
	if digital.length_squared() > 0.01:
		return digital.normalized()

	# --- Analogstick auslesen (falls Joypad vorhanden) ---
	# Nur lesen wenn ein Joypad zugewiesen ist.
	if joypad_index >= 0:
		var analog := Vector2(
			Input.get_joy_axis(joypad_index, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(joypad_index, JOY_AXIS_LEFT_Y)
		)
		# Deadzone: alles unter ANALOG_DEADZONE ignorieren
		if analog.length() > ANALOG_DEADZONE:
			return analog.normalized()

	return Vector2.ZERO

# Gibt zurueck ob eine bestimmte Aktion gerade gedrueckt ist.
# action_suffix = z.B. "attack", "dodge", "special" – OHNE Spieler-Prefix.
# Beachtet input_blocked: Aktionen sind gesperrt wenn Flag gesetzt.
func is_action_pressed(action_suffix: String) -> bool:
	if input_blocked:
		return false
	var action: String = ACTION_PREFIXES[player_id] + action_suffix
	# Guard: Action muss in InputMap definiert sein, sonst Fehler vermeiden
	if not InputMap.has_action(action):
		push_warning("PlayerInput: Action '%s' nicht in InputMap definiert." % action)
		return false
	return Input.is_action_pressed(action)

# Gibt zurueck ob eine Aktion in diesem Frame frisch gedrueckt wurde (rising edge).
# Wird fuer Dodge, Spell-Cast-Trigger etc. genutzt (einmalige Ausloesung, nicht dauerhaft).
func is_action_just_pressed(action_suffix: String) -> bool:
	if input_blocked:
		return false
	var action: String = ACTION_PREFIXES[player_id] + action_suffix
	if not InputMap.has_action(action):
		push_warning("PlayerInput: Action '%s' nicht in InputMap definiert." % action)
		return false
	return Input.is_action_just_pressed(action)

# Gibt zurueck ob eine Aktion in diesem Frame losgelassen wurde (falling edge).
# Wird fuer L/R-Tippen/Halten-Logik im motion_input_parser (Phase 2A) genutzt.
func is_action_just_released(action_suffix: String) -> bool:
	# Hinweis: Aktionen die gerade losgelassen wurden sollen trotz input_blocked
	# registriert werden – damit L/R-Tippen/Halten korrekt endet.
	var action: String = ACTION_PREFIXES[player_id] + action_suffix
	if not InputMap.has_action(action):
		push_warning("PlayerInput: Action '%s' nicht in InputMap definiert." % action)
		return false
	return Input.is_action_just_released(action)

# Sperrt alle Aktions-Inputs (Bewegung bleibt blockiert).
# Wird von status_effect_component.gd aufgerufen bei Betaeubung oder Einfrieren.
func block_input() -> void:
	input_blocked = true

# Gibt den Input wieder frei.
# Wird von status_effect_component.gd aufgerufen wenn CC-Effekt endet.
func unblock_input() -> void:
	input_blocked = false

# =============================================================================
# INITIALISIERUNG
# =============================================================================

# Setzt Spieler-Index und Joypad-Zuordnung in einem Schritt.
# Wird von player_spawner.gd (Phase 3B) oder direkt in player.gd aufgerufen.
# player_idx: 0–3 | joy_idx: -1 fuer Tastatur, >=0 fuer Joypad
func init(player_idx: int, joy_idx: int) -> void:
	player_id = clamp(player_idx, 0, 3)
	joypad_index = joy_idx
