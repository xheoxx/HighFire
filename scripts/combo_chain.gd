# =============================================================================
# DATEINAME: combo_chain.gd
# ZWECK:     Visualisiert die aktuelle Eingabekette als Line2D-Pfad.
#            Jeder Richtungsstep verlaengert die Linie; clear_chain() setzt sie
#            fuer neue Gesten oder Fehlversuche zurueck.
# ABHAENGIG VON: scenes/combo_chain_ui.tscn, motion_input_parser.gd
# =============================================================================

class_name ComboChain
extends Line2D

# Pixel-Abstand pro Input-Schritt in der Rune-Kette.
@export var step_length: float = 16.0

# Maximale Punkte in der Kette (alt = vorne entfernen).
@export var max_points: int = 12

# Startpunkt der Kette in lokalen Koordinaten.
@export var start_position: Vector2 = Vector2.ZERO

# Letzte Richtung, um optional gleiche Folge-Richtungen zu glätten.
var _last_direction: int = -1

# Initialisiert Basispunkt und Linien-Stil-Fallbacks.
func _ready() -> void:
	if points.is_empty():
		add_point(start_position)

	if width <= 0.0:
		width = 4.0

# Fuegt einen Richtungsstep als neuen Linienpunkt hinzu.
func add_direction(direction: int) -> void:
	var direction_vec: Vector2 = _direction_to_vector(direction)
	if direction_vec == Vector2.ZERO:
		return

	var previous: Vector2 = points[points.size() - 1]
	var next_point: Vector2 = previous + (direction_vec * step_length)
	add_point(next_point)
	_last_direction = direction

	while points.size() > max_points:
		remove_point(0)

# Leert die Rune-Kette und setzt sie auf den Startpunkt zurueck.
func clear_chain() -> void:
	clear_points()
	add_point(start_position)
	_last_direction = -1

# Wandelt die Direction-Enums aus motion_input_parser.gd in Vektoren um.
func _direction_to_vector(direction: int) -> Vector2:
	match direction:
		0:  # UP
			return Vector2.UP
		1:  # DOWN
			return Vector2.DOWN
		2:  # LEFT
			return Vector2.LEFT
		3:  # RIGHT
			return Vector2.RIGHT
		4:  # UP_RIGHT
			return Vector2(1.0, -1.0).normalized()
		5:  # UP_LEFT
			return Vector2(-1.0, -1.0).normalized()
		6:  # DOWN_RIGHT
			return Vector2(1.0, 1.0).normalized()
		7:  # DOWN_LEFT
			return Vector2(-1.0, 1.0).normalized()
	return Vector2.ZERO
