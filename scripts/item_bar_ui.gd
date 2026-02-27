# =============================================================================
# DATEINAME: item_bar_ui.gd
# ZWECK:     HUD-Element das die aktiven Items eines Spielers als horizontale
#            Leiste anzeigt. Reagiert auf item_added und item_consumed Signale
#            von item_system.gd. Kein Slot-Limit in der Testphase (dynamisch).
# ABHAENGIG VON: item_system.gd (Signale), item_config.tres (Farben)
# =============================================================================

class_name ItemBarUI
extends Control

# =============================================================================
# NODE-REFERENZEN
# =============================================================================

# HBoxContainer der alle Item-Slots haelt (dynamisch befullt)
@onready var item_container: HBoxContainer = $ItemContainer

# =============================================================================
# KONFIGURATION
# =============================================================================

# Breite/Hoehe eines einzelnen Item-Slots in Pixeln
const SLOT_SIZE: int = 24

# Abstand zwischen Slots
const SLOT_SPACING: int = 2

# =============================================================================
# INTERNE STATE
# =============================================================================

# Aktive Item-Slot-Nodes: { "item_id_unique_key": slot_node }
# Eindeutiger Key weil mehrere Items mit gleicher ID moeglich sind
var _slot_nodes: Dictionary = {}

# Geladene Item-Konfiguration fuer Farben
var _config: Resource

# Zaehler fuer eindeutige Slot-Keys
var _slot_counter: int = 0

# Spieler-ID dieses HUDs (fuer Signal-Filter)
var player_id: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

# Laedt Konfiguration.
func _ready() -> void:
	_config = load("res://resources/item_config.tres")

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Verbindet dieses HUD mit dem ItemSystem.
# Wird nach dem Spawnen des Spielers aufgerufen.
func connect_to_item_system(item_system: ItemSystem, p_id: int) -> void:
	player_id = p_id
	if item_system:
		item_system.item_added.connect(_on_item_added)
		item_system.item_consumed.connect(_on_item_consumed)

# =============================================================================
# SIGNAL-HANDLER
# =============================================================================

# Fuegt einen neuen Item-Slot hinzu wenn ein Item aufgesammelt wird.
func _on_item_added(p_id: int, item_id: String) -> void:
	if p_id != player_id:
		return
	_add_item_slot(item_id)

# Entfernt/graut den Item-Slot aus wenn ein Item verbraucht wurde.
func _on_item_consumed(p_id: int, item_id: String) -> void:
	if p_id != player_id:
		return
	_consume_item_slot(item_id)

# =============================================================================
# SLOT-VERWALTUNG
# =============================================================================

# Erstellt einen neuen Item-Slot in der Leiste.
func _add_item_slot(item_id: String) -> void:
	if not item_container:
		return

	var slot: Control = _create_slot(item_id)
	var key: String = item_id + "_" + str(_slot_counter)
	_slot_counter += 1
	_slot_nodes[key] = {"node": slot, "item_id": item_id}
	item_container.add_child(slot)

	# Flash-Animation beim Hinzufuegen
	_play_slot_flash(slot)

# Graut den aeltesten nicht-konsumierten Slot fuer diese item_id aus und entfernt ihn.
func _consume_item_slot(item_id: String) -> void:
	for key in _slot_nodes.keys():
		var slot_data: Dictionary = _slot_nodes[key]
		if str(slot_data.get("item_id", "")) == item_id and not bool(slot_data.get("consumed", false)):
			slot_data["consumed"] = true
			var slot_node: Control = slot_data.get("node")
			if slot_node:
				_play_consume_animation(slot_node, key)
			return

# Erstellt den visuellen Slot-Node.
func _create_slot(item_id: String) -> Control:
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

	# Hintergrund (Element-Farbe)
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	bg.color = _get_item_bg_color(item_id)
	slot.add_child(bg)

	# Symbol-Label
	var label: Label = Label.new()
	label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.text = _get_item_symbol(item_id)
	slot.add_child(label)

	return slot

# Spielt den Flash-Tween beim Aufsammeln ab (kurzes Aufleuchten in Weiss).
func _play_slot_flash(slot: Control) -> void:
	if not _config:
		return
	var duration: float = float(_config.get("hud_flash_duration") if _config.get("hud_flash_duration") != null else 0.25)

	var tween: Tween = create_tween()
	tween.tween_property(slot, "modulate", Color.WHITE, duration * 0.5)
	tween.tween_property(slot, "modulate", Color(1, 1, 1, 1), duration * 0.5)

# Spielt die Ausgrau-/Ausblend-Animation ab wenn ein Item verbraucht wird.
func _play_consume_animation(slot_node: Control, key: String) -> void:
	if not _config:
		slot_node.queue_free()
		_slot_nodes.erase(key)
		return

	var duration: float = float(_config.get("hud_consumed_fade_duration") if _config.get("hud_consumed_fade_duration") != null else 0.5)

	var tween: Tween = create_tween()
	tween.tween_property(slot_node, "modulate", Color(0.4, 0.4, 0.4, 0.5), duration)
	tween.tween_callback(func():
		slot_node.queue_free()
		_slot_nodes.erase(key)
	)

# =============================================================================
# HELPER
# =============================================================================

# Gibt die HUD-Hintergrundfarbe fuer ein Item zurueck.
func _get_item_bg_color(item_id: String) -> Color:
	if not _config:
		return Color(0.2, 0.2, 0.3, 1.0)

	var ids: Array = _config.get("item_ids") if _config.get("item_ids") else []
	var categories: Array = _config.get("item_categories") if _config.get("item_categories") else []
	var idx: int = ids.find(item_id)
	if idx < 0 or idx >= categories.size():
		return Color(0.2, 0.2, 0.3, 1.0)

	var category: String = str(categories[idx])
	var hex: String = str(_config.get("color_" + category) if _config.get("color_" + category) != null else "#333344")
	return Color(hex)

# Gibt das Icon-Symbol fuer ein Item zurueck.
func _get_item_symbol(item_id: String) -> String:
	match item_id:
		"shield_shard":
			return "🛡"
		"ember_core":
			return "🔥"
		"frost_vein":
			return "❄"
		"speed_rune":
			return "⚡"
		"life_shard":
			return "♥"
		"dodge_crystal":
			return "◇"
		"overcharge":
			return "✦"
		"terrain_anchor":
			return "⚓"
	return "?"
