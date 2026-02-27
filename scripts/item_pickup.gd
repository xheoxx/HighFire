# =============================================================================
# DATEINAME: item_pickup.gd
# ZWECK:     Area2D-Node der ein Item auf dem Boden repraesentiert.
#            Emittiert picked_up(item_id, player_id) wenn ein Spieler darueber
#            laeuft. Zeigt das Item als kleines ColorRect + Label an und
#            spielt eine kurze Einblend-Animation beim Spawn.
# ABHAENGIG VON: item_config.tres (Farb-Kodierung), item_system.gd
# =============================================================================

class_name ItemPickup
extends Area2D

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn ein Spieler das Item aufsammelt.
# item_system.gd verbindet sich mit diesem Signal.
signal picked_up(item_id: String, player_id: int)

# =============================================================================
# PARAMETER (von item_system.gd gesetzt bevor add_child)
# =============================================================================

# ID des Items das dieses Pickup repraesentiert
var item_id: String = ""

# =============================================================================
# NODE-REFERENZEN
# =============================================================================

var _visual: ColorRect
var _label: Label

# =============================================================================
# LIFECYCLE
# =============================================================================

# Erstellt visuelle Darstellung und Kollisionsform, startet Einblend-Animation.
func _ready() -> void:
	# Zur Gruppe hinzufuegen fuer einfache Abfragen
	add_to_group("item_pickups")

	# Kollisions-Layer: Items (Layer 5 oder aehnlich)
	collision_layer = 0
	collision_mask = 1  # Spieler-Layer

	# Kollisionsform
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	shape_node.shape = circle
	add_child(shape_node)

	# Visueller Platzhalter: ColorRect + Label
	_visual = ColorRect.new()
	_visual.size = Vector2(16, 16)
	_visual.position = Vector2(-8, -8)
	_visual.color = _get_item_color()
	_visual.modulate.a = 0.0  # Startet unsichtbar fuer Einblend-Animation
	add_child(_visual)

	_label = Label.new()
	_label.position = Vector2(-8, -8)
	_label.size = Vector2(16, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.text = _get_item_symbol()
	add_child(_label)

	# Kollisions-Signal verbinden
	body_entered.connect(_on_body_entered)

	# Einblend-Animation
	_play_appear_animation()

# =============================================================================
# KOLLISION
# =============================================================================

# Wird aufgerufen wenn ein Spieler ueber das Item laeuft.
func _on_body_entered(body: Node) -> void:
	var player: Player = body as Player
	if not player:
		return

	picked_up.emit(item_id, player.player_id)
	_play_collect_animation()

# =============================================================================
# ANIMATIONEN
# =============================================================================

# Kurze Einblend-Animation beim Spawnen (Tween: Alpha 0 → 1).
func _play_appear_animation() -> void:
	var config: Resource = load("res://resources/item_config.tres")
	var duration: float = 0.3
	if config and config.get("pickup_appear_duration") != null:
		duration = float(config.get("pickup_appear_duration"))

	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate:a", 1.0, duration)

# Kurze Ausblend-Animation beim Aufsammeln, dann Node entfernen.
func _play_collect_animation() -> void:
	# Neue Kollision deaktivieren damit kein Doppel-Pick
	set_deferred("monitoring", false)

	var config: Resource = load("res://resources/item_config.tres")
	var duration: float = 0.2
	if config and config.get("pickup_collect_duration") != null:
		duration = float(config.get("pickup_collect_duration"))

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate:a", 0.0, duration)
	tween.tween_property(_visual, "scale", Vector2(1.5, 1.5), duration)
	tween.tween_callback(queue_free).set_delay(duration)

# =============================================================================
# HELPER
# =============================================================================

# Gibt die HUD-Hintergrundfarbe des Items zurueck (aus item_config.tres).
func _get_item_color() -> Color:
	var config: Resource = load("res://resources/item_config.tres")
	if not config:
		return Color(0.2, 0.2, 0.3, 1.0)

	var ids: Array = config.get("item_ids") if config.get("item_ids") else []
	var categories: Array = config.get("item_categories") if config.get("item_categories") else []

	var idx: int = ids.find(item_id)
	if idx < 0 or idx >= categories.size():
		return Color(0.2, 0.2, 0.3, 1.0)

	var category: String = str(categories[idx])
	var color_key: String = "color_" + category
	var hex: String = str(config.get(color_key) if config.get(color_key) != null else "#333344")
	return Color(hex)

# Gibt das Symbol des Items als Text zurueck (fuer das Label).
func _get_item_symbol() -> String:
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
