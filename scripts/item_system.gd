# =============================================================================
# DATEINAME: item_system.gd
# ZWECK:     Verwaltet aktive Items pro Spieler. Prueft Bedingungen fuer
#            bedingte Items in _process(). Koordiniert Item-Drops aus
#            tile.gd und Item-Aufnahme aus item_pickup.gd.
#            Emittiert Signale fuer HUD-Updates (item_added, item_consumed).
# ABHAENGIG VON: item_config.tres, item_pickup.gd, player.gd,
#                spell_system.gd (overcharge-Integration),
#                status_effect_component.gd (ember_core, frost_vein)
# =============================================================================

class_name ItemSystem
extends Node

# =============================================================================
# SIGNALE
# =============================================================================

# Spieler hat ein Item aufgesammelt.
# item_bar_ui.gd und andere Systeme hoeren auf dieses Signal.
signal item_added(player_id: int, item_id: String)

# Item wurde verbraucht (Effekt ausgeloest oder abgelaufen).
signal item_consumed(player_id: int, item_id: String)

# Wird gesendet wenn ein Hit-Effekt ausgeloest wird (ember_core, frost_vein).
# target_id: Spieler-ID des getroffenen Ziels
signal on_hit_effect(attacker_id: int, target_id: int)

# =============================================================================
# INTERNE STATE
# =============================================================================

# Geladene Item-Konfiguration aus item_config.tres
var _config: Resource

# Aktive Items pro Spieler-ID:
# { player_id: [ { "id": "shield_shard", "timer": 5.0, "is_consumed": false }, ... ] }
var _player_items: Dictionary = {}

# Pickup-Scene voraufladen
var _pickup_scene: PackedScene

# Referenz auf alle Spieler-Nodes (aus "players"-Gruppe)
# Wird einmalig in _ready() gecacht und beim Spawnen von Spielern aktualisiert.
var _players: Array = []

# =============================================================================
# LIFECYCLE
# =============================================================================

# Laedt Konfiguration und Pickup-Szene.
func _ready() -> void:
	_config = load("res://resources/item_config.tres")
	if ResourceLoader.exists("res://scenes/item_pickup.tscn"):
		_pickup_scene = load("res://scenes/item_pickup.tscn")

# Prueft Bedingungen fuer bedingte Items und entfernt abgelaufene Items.
func _process(delta: float) -> void:
	_players = get_tree().get_nodes_in_group("players")
	_tick_item_timers(delta)
	_check_conditional_items()

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Prueft ob auf diesem Tile-Position ein Item gedropt wird und spawnt es.
# Wird von tile.gd aufgerufen wenn ein Tile DESTROYED wird.
func try_drop(tile_position: Vector2) -> void:
	if not _config:
		return

	var drop_chance: float = float(_config.get("item_drop_chance") if _config.get("item_drop_chance") != null else 0.15)
	if randf() > drop_chance:
		return

	var item_id: String = _roll_item_type()
	if item_id.is_empty():
		return

	_spawn_pickup(tile_position, item_id)

# Fuegt ein Item zum Inventar eines Spielers hinzu (aufgerufen von item_pickup.gd).
func add_item(player_id: int, item_id: String) -> void:
	if not _config:
		return

	# Max-Items-Check (0 = keine Begrenzung)
	var max_items: int = int(_config.get("max_items_per_player") if _config.get("max_items_per_player") != null else 0)
	if max_items > 0:
		var current: Array = _player_items.get(player_id, [])
		if current.size() >= max_items:
			return

	if not _player_items.has(player_id):
		_player_items[player_id] = []

	var item_entry: Dictionary = {
		"id": item_id,
		"is_consumed": false,
		"timer": _get_item_duration(item_id),
		"is_active": false,
	}
	_player_items[player_id].append(item_entry)

	_apply_passive_item(player_id, item_id, item_entry)
	item_added.emit(player_id, item_id)

# Gibt den Geschwindigkeits-Multiplikator eines Spielers durch aktive Items zurueck.
# Wird von player.gd in _physics_process verwendet.
func get_speed_multiplier(player_id: int) -> float:
	var items: Array = _player_items.get(player_id, [])
	var mult: float = 1.0
	for item in items:
		if item["id"] == "speed_rune" and not item["is_consumed"]:
			var speed_mult: float = float(_config.get("speed_rune_speed_multiplier") if _config.get("speed_rune_speed_multiplier") != null else 1.2)
			mult *= speed_mult
	return mult

# Gibt den Schadens-Modifikator fuer einen Spieler zurueck (shield_shard, overcharge).
# damage_system.gd ruft das vor Schadensanwendung ab.
func get_damage_modifier(player_id: int) -> float:
	var items: Array = _player_items.get(player_id, [])
	for item in items:
		if item["id"] == "shield_shard" and not item["is_consumed"]:
			var reduction: float = float(_config.get("shield_shard_damage_reduction") if _config.get("shield_shard_damage_reduction") != null else 0.5)
			_consume_item(player_id, item)
			return reduction  # Schaden wird um 50% reduziert
	return 1.0

# Prueft ob ein Spieler den Terrain-Anker traegt (faellt nicht durch Loecher).
func has_terrain_anchor(player_id: int) -> bool:
	var items: Array = _player_items.get(player_id, [])
	for item in items:
		if item["id"] == "terrain_anchor" and not item["is_consumed"]:
			return true
	return false

# Gibt den naechsten Spell-Schaden-Multiplikator zurueck (overcharge).
# Aktiviert Overcharge auf spell_system wenn vorhanden.
func check_overcharge_for_spell(player_id: int) -> float:
	var items: Array = _player_items.get(player_id, [])
	for item in items:
		if item["id"] == "overcharge" and not item["is_consumed"]:
			_consume_item(player_id, item)
			return float(_config.get("overcharge_damage_multiplier") if _config.get("overcharge_damage_multiplier") != null else 2.0)
	return 1.0

# =============================================================================
# PASSIVE ITEM-ANWENDUNG (bei Aufnahme)
# =============================================================================

# Wendet sofortige Item-Effekte an (bei Aufnahme des Items).
func _apply_passive_item(player_id: int, item_id: String, item_entry: Dictionary) -> void:
	var player: Player = _get_player(player_id)
	if not player:
		return

	match item_id:
		"speed_rune":
			# Geschwindigkeit sofort erhoehen (item_system.get_speed_multiplier wird von player.gd abgefragt)
			item_entry["is_active"] = true

		"terrain_anchor":
			item_entry["is_active"] = true

		"ember_core":
			# Registriert sich als Hit-Listener – wird in on_hit_effect emittiert
			item_entry["is_active"] = true

		"frost_vein":
			item_entry["is_active"] = true

		"overcharge":
			# Overcharge: naechster Spell 2x Schaden – wird bei Spell-Cast konsumiert
			item_entry["is_active"] = true
			var spell_sys: SpellSystem = player.get_node_or_null("SpellSystem") as SpellSystem
			if spell_sys:
				spell_sys.activate_overcharge()

		_:
			item_entry["is_active"] = true

# =============================================================================
# BEDINGTE ITEMS (_process-Check)
# =============================================================================

# Prueft alle bedingten Items auf ihre Trigger-Bedingung.
func _check_conditional_items() -> void:
	for player_id in _player_items.keys():
		var items: Array = _player_items[player_id]
		var player: Player = _get_player(player_id)
		if not player:
			continue

		for item in items:
			if item["is_consumed"]:
				continue
			match item["id"]:
				"life_shard":
					_check_life_shard(player_id, player, item)
				"dodge_crystal":
					_check_dodge_crystal(player_id, player, item)

# Prueft ob HP unter den Schwellwert gefallen sind (life_shard).
func _check_life_shard(player_id: int, player: Player, item: Dictionary) -> void:
	if not _config:
		return
	var threshold: float = float(_config.get("life_shard_hp_threshold") if _config.get("life_shard_hp_threshold") != null else 0.3)
	var heal_amount: int = int(_config.get("life_shard_heal_amount") if _config.get("life_shard_heal_amount") != null else 25)

	if player.max_hp > 0 and float(player.current_hp) / float(player.max_hp) <= threshold:
		player.heal(heal_amount)
		_consume_item(player_id, item)

# Prueft ob ein Projektil zu nah ist und loest Auto-Dodge aus (dodge_crystal).
func _check_dodge_crystal(player_id: int, player: Player, item: Dictionary) -> void:
	if not _config:
		return
	var proximity: float = float(_config.get("dodge_crystal_proximity_px") if _config.get("dodge_crystal_proximity_px") != null else 80.0)

	# Alle Projektile in der Szene pruefen
	var projectiles: Array = get_tree().get_nodes_in_group("spell_projectiles")
	for proj in projectiles:
		if proj is SpellProjectile and proj.caster_player_id != player_id:
			if proj.global_position.distance_to(player.global_position) <= proximity:
				# Auto-Dodge ausloesen
				if player.has_method("_start_dodge"):
					player.call("_start_dodge")
				_consume_item(player_id, item)
				return

# =============================================================================
# ITEM TIMER UND ABLAUF
# =============================================================================

# Tickt Item-Timer und konsumiert abgelaufene Items.
func _tick_item_timers(delta: float) -> void:
	for player_id in _player_items.keys():
		var items: Array = _player_items[player_id]
		for item in items:
			if item["is_consumed"]:
				continue
			if item["timer"] > 0.0:
				item["timer"] -= delta
				if item["timer"] <= 0.0:
					_consume_item(player_id, item)

		# Verbrauchte Items entfernen
		_player_items[player_id] = items.filter(func(i): return not i["is_consumed"])

# Markiert ein Item als verbraucht und loest Signal aus.
func _consume_item(player_id: int, item: Dictionary) -> void:
	if item["is_consumed"]:
		return
	item["is_consumed"] = true
	item_consumed.emit(player_id, str(item["id"]))

# =============================================================================
# ITEM-DROP
# =============================================================================

# Wuerfelt den Item-Typ basierend auf der Gewichtungstabelle.
func _roll_item_type() -> String:
	if not _config:
		return ""

	var weights: Array = _config.get("item_weights") if _config.get("item_weights") else []
	var ids: Array = _config.get("item_ids") if _config.get("item_ids") else []

	if weights.is_empty() or ids.is_empty() or weights.size() != ids.size():
		return ""

	var total_weight: int = 0
	for w in weights:
		total_weight += int(w)

	var roll: int = randi_range(0, total_weight - 1)
	var cumulative: int = 0
	for i in range(weights.size()):
		cumulative += int(weights[i])
		if roll < cumulative:
			return str(ids[i])

	return str(ids[ids.size() - 1])

# Spawnt eine Item-Pickup-Node an der angegebenen Position.
func _spawn_pickup(position: Vector2, item_id: String) -> void:
	if not _pickup_scene:
		return

	var pickup: ItemPickup = _pickup_scene.instantiate() as ItemPickup
	if not pickup:
		return

	pickup.item_id = item_id
	pickup.global_position = position
	pickup.picked_up.connect(_on_item_picked_up)
	get_tree().current_scene.add_child(pickup)

# =============================================================================
# SIGNAL-HANDLER
# =============================================================================

# Wird aufgerufen wenn ein Spieler ein Item aufsammelt.
func _on_item_picked_up(item_id: String, player_id: int) -> void:
	add_item(player_id, item_id)

# =============================================================================
# HELPER
# =============================================================================

# Gibt die Lebensdauer eines Items zurueck (Items ohne Timer haben -1).
func _get_item_duration(item_id: String) -> float:
	match item_id:
		"speed_rune":
			return float(_config.get("speed_rune_duration") if _config else 8.0)
		"terrain_anchor":
			return float(_config.get("terrain_anchor_duration") if _config else 6.0)
		"overcharge":
			return float(_config.get("overcharge_expire_time") if _config else 10.0)
	return -1.0  # Kein Timer: bedingte Items laufen bei Bedingungsausloesung ab

# Gibt den Player-Node fuer eine Spieler-ID zurueck.
func _get_player(player_id: int) -> Player:
	for p in _players:
		if p is Player and p.player_id == player_id:
			return p
	return null
