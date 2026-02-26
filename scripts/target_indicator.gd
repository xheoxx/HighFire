# =============================================================================
# DATEINAME: target_indicator.gd
# ZWECK:     Steuert den visuellen Target-Lock-Ring der um ein Ziel erscheint.
#            Baut den Line2D-Kreis dynamisch aus Sinus/Kosinus-Punkten auf
#            (32 Punkte, Radius 20px) und animiert die Linienbreite pulsierend.
#            Bietet set_color(color) an damit target_system.gd die Angreifer-Farbe setzen kann.
# ABHAENGIG VON: target_indicator.tscn (Node-Baum: Ring als Line2D, AnimationPlayer)
# =============================================================================

extends Node2D

# =============================================================================
# KONSTANTEN
# =============================================================================

# Radius des Rings in Pixeln.
# Muss groesser sein als der Spieler-Kollisionsradius (ca. 12px) damit er sichtbar ist.
const RING_RADIUS: float = 20.0

# Anzahl der Punkte fuer den Kreis-Approximation.
# 32 Punkte ergeben eine glatte Darstellung ohne sichtbare Ecken.
const RING_POINTS: int = 32

# Pulsier-Geschwindigkeit in Hertz (Zyklen pro Sekunde).
const PULSE_HZ: float = 1.2

# Minimale und maximale Linienbreite beim Pulsieren.
const PULSE_WIDTH_MIN: float = 1.5
const PULSE_WIDTH_MAX: float = 3.5

# =============================================================================
# NODE-REFERENZEN
# =============================================================================

# Line2D-Node der den Ring darstellt.
@onready var ring: Line2D = $Ring

# AnimationPlayer fuer das Pulsieren (alternativ: Tween direkt in _process).
# In dieser Implementierung nutzen wir _process() direkt fuer mehr Kontrolle.
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Pulsier-Phase (laeuft in _process auf und wird fuer Sinus genutzt)
var _pulse_phase: float = 0.0

# =============================================================================
# GODOT-LIFECYCLE
# =============================================================================

# _ready() baut den Kreis aus RING_POINTS Punkten auf.
# Line2D in Godot zeichnet eine Linie durch alle Punkte – kein nativer Kreis-Node.
func _ready() -> void:
	_build_ring()

# _process(delta) animiert das Pulsieren der Linienbreite.
# Laeuft nur wenn der Node sichtbar ist (visible = true wird von target_system.gd gesetzt).
func _process(delta: float) -> void:
	_pulse_phase += delta * PULSE_HZ * TAU  # TAU = 2*PI
	var t: float = (sin(_pulse_phase) + 1.0) * 0.5  # 0.0 bis 1.0
	ring.width = lerp(PULSE_WIDTH_MIN, PULSE_WIDTH_MAX, t)

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Setzt die Farbe des Rings.
# Wird von target_system.gd aufgerufen wenn ein Ziel gesetzt wird.
# Farbe = Primärfarbe des Angreifers (lt. DESIGN.md Spieler-Farbidentitaet).
func set_color(color: Color) -> void:
	if ring:
		ring.default_color = color

# =============================================================================
# INTERNE LOGIK
# =============================================================================

# Baut den Kreis als PackedVector2Array aus RING_POINTS gleichmaessig verteilten Punkten.
# Letzter Punkt = erster Punkt damit der Kreis geschlossen ist (kein Spalt).
func _build_ring() -> void:
	if not ring:
		return

	var points := PackedVector2Array()
	points.resize(RING_POINTS + 1)  # +1 fuer den Schlusspunkt der den Kreis schliesst

	for i in range(RING_POINTS + 1):
		# Winkel gleichmaessig verteilt ueber 360 Grad (TAU = 2*PI)
		var angle: float = (float(i) / RING_POINTS) * TAU
		points[i] = Vector2(cos(angle) * RING_RADIUS, sin(angle) * RING_RADIUS)

	ring.points = points
