# =============================================================================
# DATEINAME: status_effect_hud.gd
# ZWECK:     Zeigt Icons fuer aktive Statuseffekte direkt ueber dem Spieler-
#            Charakter an (in der Spielwelt, nicht auf dem Screen-HUD).
#            Reagiert auf effect_changed-Signale von status_effect_component.gd.
#            Icons: ColorRect + Stack-Label + Timer-Balken (nur sichtbar wenn > 0 Stacks).
# ABHAENGIG VON: status_effect_component.gd (Signal effect_changed),
#                resources/status_effects.tres (Icon-Farben)
# =============================================================================

class_name StatusEffectHUD
extends Node2D

# =============================================================================
# KONFIGURATION
# =============================================================================

# Breite eines einzelnen Effekt-Icons in Pixeln
const ICON_WIDTH: int = 16
# Hoehe eines einzelnen Effekt-Icons
const ICON_HEIGHT: int = 16
# Abstand zwischen Icons
const ICON_SPACING: int = 2
# Y-Versatz ueber dem Spieler (negativ = nach oben)
const ICON_Y_OFFSET: int = -36
# Maximale Anzahl sichtbarer Icon-Slots
const MAX_VISIBLE_ICONS: int = 5
# Timer-Balken-Hoehe in Pixeln
const TIMER_BAR_HEIGHT: int = 2

# =============================================================================
# INTERNE STATE
# =============================================================================

# Dictionary aktiver Icon-Nodes: { "burning": { "container", "label", "timer_bar" } }
var _icon_nodes: Dictionary = {}

# Geladene Effekt-Konfiguration fuer Farben
var _effects_config: Resource

# =============================================================================
# LIFECYCLE
# =============================================================================

# Laedt Konfiguration und verbindet mit StatusEffectComponent.
func _ready() -> void:
	_effects_config = load("res://resources/status_effects.tres")

# Verbindet dieses HUD mit der StatusEffectComponent des Spielers.
# Wird nach dem Spawnen des Spielers aufgerufen.
func connect_to_component(component: StatusEffectComponent) -> void:
	if component:
		component.effect_changed.connect(_on_effect_changed)

# =============================================================================
# SIGNAL-HANDLER
# =============================================================================

# Aktualisiert die Icon-Darstellung wenn sich ein Effekt aendert.
# effect_id: z.B. "burning", stack_count: 0 = Effekt vorbei
func _on_effect_changed(effect_id: String, stack_count: int) -> void:
	if stack_count <= 0:
		_remove_icon(effect_id)
	else:
		_update_icon(effect_id, stack_count)
	_reposition_icons()

# =============================================================================
# ICON-VERWALTUNG
# =============================================================================

# Erstellt oder aktualisiert das Icon fuer einen Effekt.
func _update_icon(effect_id: String, stack_count: int) -> void:
	if not _icon_nodes.has(effect_id):
		_create_icon(effect_id)

	var icon_data: Dictionary = _icon_nodes[effect_id]
	var label: Label = icon_data.get("label")
	if label:
		label.text = str(stack_count) if stack_count > 1 else ""

# Erstellt einen neuen Icon-Node fuer den Effekt.
func _create_icon(effect_id: String) -> void:
	var icon_color: Color = _get_icon_color(effect_id)

	# Container-Node fuer alle Sub-Elemente
	var container: Node2D = Node2D.new()
	add_child(container)

	# Hintergrund-ColorRect
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(ICON_WIDTH, ICON_HEIGHT)
	bg.position = Vector2(-ICON_WIDTH / 2.0, 0)
	bg.color = icon_color
	container.add_child(bg)

	# Stack-Anzahl-Label
	var label: Label = Label.new()
	label.position = Vector2(-ICON_WIDTH / 2.0, -1)
	label.size = Vector2(ICON_WIDTH, ICON_HEIGHT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(label)

	# Timer-Balken am unteren Rand
	var timer_bar: ColorRect = ColorRect.new()
	timer_bar.size = Vector2(ICON_WIDTH, TIMER_BAR_HEIGHT)
	timer_bar.position = Vector2(-ICON_WIDTH / 2.0, ICON_HEIGHT - TIMER_BAR_HEIGHT)
	timer_bar.color = Color.WHITE
	container.add_child(timer_bar)

	_icon_nodes[effect_id] = {
		"container": container,
		"label": label,
		"timer_bar": timer_bar,
		"bg": bg,
	}

# Entfernt das Icon fuer einen Effekt (mit kurzer Alpha-Tween).
func _remove_icon(effect_id: String) -> void:
	if not _icon_nodes.has(effect_id):
		return

	var icon_data: Dictionary = _icon_nodes[effect_id]
	var container: Node2D = icon_data.get("container")
	if container:
		var tween: Tween = create_tween()
		tween.tween_property(container, "modulate:a", 0.0, 0.5)
		tween.tween_callback(container.queue_free)

	_icon_nodes.erase(effect_id)

# Positioniert alle aktiven Icons nebeneinander ueber dem Spieler.
func _reposition_icons() -> void:
	var effect_ids: Array = _icon_nodes.keys()
	var total_count: int = min(effect_ids.size(), MAX_VISIBLE_ICONS)
	var total_width: float = total_count * (ICON_WIDTH + ICON_SPACING) - ICON_SPACING
	var start_x: float = -total_width / 2.0

	for i in range(total_count):
		var eff_id: String = effect_ids[i]
		var icon_data: Dictionary = _icon_nodes[eff_id]
		var container: Node2D = icon_data.get("container")
		if container:
			container.position = Vector2(start_x + i * (ICON_WIDTH + ICON_SPACING), ICON_Y_OFFSET)
			container.visible = true

	# Zu viele Icons: "+N"-Hinweis (wird in dieser Version uebersprungen)

# =============================================================================
# TIMER-BALKEN UPDATE
# =============================================================================

# Aktualisiert den Timer-Balken eines Icons (aufgerufen von StatusEffectComponent).
# normalized_time: 0.0 = fast abgelaufen, 1.0 = frisch hinzugefuegt
func update_timer_bar(effect_id: String, normalized_time: float) -> void:
	if not _icon_nodes.has(effect_id):
		return
	var timer_bar: ColorRect = _icon_nodes[effect_id].get("timer_bar")
	if timer_bar:
		timer_bar.size.x = normalized_time * ICON_WIDTH
		# Alpha-Fade in letzten 0.5s
		timer_bar.modulate.a = 1.0 if normalized_time > 0.2 else normalized_time / 0.2

# =============================================================================
# HELPER
# =============================================================================

# Liest die Icon-Farbe fuer einen Effekt aus status_effects.tres.
func _get_icon_color(effect_id: String) -> Color:
	if _effects_config:
		var effects: Dictionary = _effects_config.get("effects") if _effects_config.get("effects") else {}
		var def: Dictionary = effects.get(effect_id, {})
		var hex: String = str(def.get("icon_color", "#FFFFFF"))
		if not hex.is_empty():
			return Color(hex)
	# Fallback-Farben nach Effekt-Typ
	match effect_id:
		"burning":
			return Color("#FF4400")
		"slow", "frozen":
			return Color("#44AAFF")
		"stun":
			return Color("#FFE000")
		"armor_break":
			return Color("#8B5E3C")
		"blind":
			return Color("#6622AA")
		"wet":
			return Color("#0088FF")
		"hot":
			return Color("#FFD700")
	return Color.WHITE
