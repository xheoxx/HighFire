# =============================================================================
# DATEINAME: spell_projectile.gd
# ZWECK:     Bewegung und Kollision eines Zauber-Projektils. Bewegt sich in
#            einer festen Richtung mit konfigurierter Geschwindigkeit und
#            wird beim Treffer (Spieler oder Terrain) aufgeloest. Wendet
#            Schaden und optionale Statuseffekte auf getroffene Ziele an.
#            Ignoriert den Caster-Spieler der das Projektil abgefeuert hat.
# ABHAENGIG VON: status_effect_component.gd (auf Ziel), player.gd
# =============================================================================

class_name SpellProjectile
extends Area2D

# =============================================================================
# PROJEKTIL-PARAMETER (werden von spell_system.gd vor add_child() gesetzt)
# =============================================================================

# Spell-Identifizierer (z.B. "fireball", "plasmabolt")
var spell_id: String = ""

# Bewegungsrichtung (normalisierter Vector2)
var direction: Vector2 = Vector2.RIGHT

# Geschwindigkeit in px/s (aus spell_values.tres)
var speed: float = 450.0

# Maximale Reichweite in Pixeln bevor das Projektil verschwindet
var max_range: float = 600.0

# Schadensbereich (zufaellig aus [damage_min, damage_max])
var damage_min: int = 18
var damage_max: int = 25

# Ob dieses Projektil den NASS-Statuseffekt anwendet
var applies_wet: bool = false

# Welchen Statuseffekt dieses Projektil anwendet (z.B. "burning")
var status_effect_id: String = ""

# Spieler-ID des Casters (wird beim Treffer ignoriert)
var caster_player_id: int = -1

# =============================================================================
# INTERNER STATE
# =============================================================================

# Zurueckgelegte Distanz seit Spawn
var _distance_traveled: float = 0.0

# Farb-Rechteck als visueller Platzhalter
var _visual: ColorRect

# Hat bereits getroffen (verhindert Mehrfach-Treffer)
var _hit: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

# Richtet Visuell und Kollisions-Maske ein.
func _ready() -> void:
	# Kollisions-Layer: Projektile (Layer 3)
	collision_layer = 4   # Layer 3 = Bit 2
	# Kollisions-Maske: trifft Spieler (Layer 1) und Terrain (Layer 2)
	collision_mask = 3

	# Kollisionsform anlegen
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	shape_node.shape = circle
	add_child(shape_node)

	# Visuellen Platzhalter anlegen (ColorRect, farb-kodiert nach Spell)
	_visual = ColorRect.new()
	_visual.size = Vector2(12, 12)
	_visual.position = Vector2(-6, -6)
	_visual.color = _get_spell_color()
	add_child(_visual)

	# Kollisions-Signal verbinden
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# Bewegt das Projektil und prueft Reichweiten-Limit.
func _physics_process(delta: float) -> void:
	if _hit:
		return

	var move: Vector2 = direction * speed * delta
	global_position += move
	_distance_traveled += move.length()

	if _distance_traveled >= max_range:
		queue_free()

# =============================================================================
# KOLLISION
# =============================================================================

# Wird aufgerufen wenn das Projektil einen StaticBody2D (Terrain) trifft.
func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	# Terrain-Kollision: Projektil auflosen
	if body is StaticBody2D:
		_destroy()

# Wird aufgerufen wenn das Projektil einen anderen Area2D (Spieler) trifft.
func _on_area_entered(area: Node) -> void:
	if _hit:
		return
	# Spieler-Kollision: Schaden anwenden
	var player: Player = area.get_parent() as Player
	if not player:
		return

	# Caster ignorieren
	if player.player_id == caster_player_id:
		return

	_apply_hit(player)

# Wendet Treffer-Effekte auf einen getroffenen Spieler an.
func _apply_hit(player: Player) -> void:
	_hit = true

	# Schaden zufuegen
	var dmg: int = randi_range(damage_min, max(damage_min, damage_max))
	player.take_damage(dmg)

	# Statuseffekte anwenden
	var sec: StatusEffectComponent = player.get_node_or_null("StatusEffectComponent") as StatusEffectComponent
	if sec:
		if not status_effect_id.is_empty():
			sec.add_effect(status_effect_id, caster_player_id)
		if applies_wet:
			sec.add_effect("wet", caster_player_id)

	_destroy()

# Loest das Projektil auf (mit kurzem Flash-Effekt via Tween).
func _destroy() -> void:
	_hit = true
	# Kurzes Aufblinken beim Einschlag
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "scale", Vector2(2.0, 2.0), 0.05)
	tween.tween_callback(queue_free)

# =============================================================================
# HELPER
# =============================================================================

# Gibt die Farbe des Projektils anhand der Spell-ID zurueck.
func _get_spell_color() -> Color:
	match spell_id:
		"fireball":
			return Color("#FF4400")
		"plasmabolt":
			return Color("#FF8800")
		"lightning_strike":
			return Color("#FFE000")
		"earth_stomp", "seismic_pulse":
			return Color("#8B5E3C")
		"shadow_jump":
			return Color("#6622AA")
		"light_beam":
			return Color("#FFD700")
		"frostwall", "ice_shield":
			return Color("#44AAFF")
	return Color.WHITE
