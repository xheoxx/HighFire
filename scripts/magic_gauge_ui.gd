# =============================================================================
# DATEINAME: magic_gauge_ui.gd
# ZWECK:     Visualisiert die Magie-Verfuegbarkeit als schmalen Balken oder
#            Glow-Indikator direkt am Spieler-HUD. Reagiert auf das
#            magic_changed(current_ratio)-Signal von spell_system.gd.
#            Kein separater Mana-Balken – visuell in den Spieler-Bereich integ.
# ABHAENGIG VON: spell_system.gd (Signal magic_changed), Spieler-Farbe
# =============================================================================

class_name MagicGaugeUI
extends Control

# =============================================================================
# NODE-REFERENZEN
# =============================================================================

# Hintergrund-Leiste (immer sichtbar, gedimmt)
@onready var background: ColorRect = $Background

# Fuell-Leiste (Breite aendert sich mit Magie-Ratio)
@onready var fill_bar: ColorRect = $FillBar

# Label fuer Status-Text ("MAGIE ERSCHOEPFT" / leer)
@onready var status_label: Label = $StatusLabel

# =============================================================================
# EXPORTS
# =============================================================================

# Breite der vollen Magie-Leiste in Pixeln
@export var max_bar_width: float = 80.0

# Farbe wenn Magie voll verfuegbar ist
@export var color_full: Color = Color("#00FFCC")

# Farbe wenn Magie fast erschoepft (< 30%)
@export var color_low: Color = Color("#FF6600")

# Farbe wenn Magie im Regen-Modus ist
@export var color_regen: Color = Color("#3366FF")

# =============================================================================
# INTERNE STATE
# =============================================================================

# Ob Magie aktuell im Regen-Modus ist (statt Aktiv-Modus)
var _in_regen_mode: bool = false

# Letzter Ratio-Wert fuer Transition
var _last_ratio: float = 1.0

# Aktiver Tween fuer smooth Uebergaenge
var _tween: Tween

# =============================================================================
# LIFECYCLE
# =============================================================================

# Setzt Startzustand der Leiste.
func _ready() -> void:
	_update_bar(1.0, false)

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Verbindet mit dem SpellSystem-Node des zugehoerigen Spielers.
# Muss nach dem Spawnen des Spielers aufgerufen werden.
func connect_to_spell_system(spell_system: SpellSystem) -> void:
	if spell_system:
		spell_system.magic_changed.connect(_on_magic_changed)
		spell_system.magic_depleted.connect(_on_magic_depleted)
		spell_system.magic_recharged.connect(_on_magic_recharged)

# Setzt die Spielerfarbe fuer den Glow-Indikator.
func set_player_color(player_color: Color) -> void:
	color_full = player_color
	_update_bar(_last_ratio, _in_regen_mode)

# =============================================================================
# SIGNAL-HANDLER
# =============================================================================

# Wird aufgerufen wenn SpellSystem den Magie-Fuellstand aendert.
# current_ratio: 0.0 (leer/regen) bis 1.0 (voll)
func _on_magic_changed(current_ratio: float) -> void:
	_last_ratio = current_ratio
	_update_bar(current_ratio, _in_regen_mode)

# Magie aufgebraucht: in Regen-Modus wechseln.
func _on_magic_depleted() -> void:
	_in_regen_mode = true
	if status_label:
		status_label.text = "MAGIE ✦"
		status_label.modulate = Color(1.0, 0.4, 0.0, 1.0)
	_update_bar(0.0, true)

# Magie vollstaendig regeneriert.
func _on_magic_recharged() -> void:
	_in_regen_mode = false
	if status_label:
		status_label.text = ""
	_update_bar(1.0, false)
	# Kurzes Aufleuchten als Feedback
	_flash_recharge()

# =============================================================================
# VISUELLE AKTUALISIERUNG
# =============================================================================

# Aktualisiert Breite und Farbe der Magie-Leiste smooth via Tween.
func _update_bar(ratio: float, in_regen: bool) -> void:
	if not fill_bar:
		return

	var target_width: float = ratio * max_bar_width
	var target_color: Color = _get_bar_color(ratio, in_regen)

	# Laufenden Tween stoppen und neuen starten
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(fill_bar, "size:x", target_width, 0.15)
	_tween.tween_property(fill_bar, "color", target_color, 0.15)

# Gibt die Balkenfarbe basierend auf Ratio und Modus zurueck.
func _get_bar_color(ratio: float, in_regen: bool) -> Color:
	if in_regen:
		return color_regen
	if ratio < 0.3:
		return color_low
	return color_full

# Kurzes Aufleuchten wenn Magie wieder voll ist.
func _flash_recharge() -> void:
	if not fill_bar:
		return
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(fill_bar, "color", Color.WHITE, 0.1)
	flash_tween.tween_property(fill_bar, "color", color_full, 0.2)
